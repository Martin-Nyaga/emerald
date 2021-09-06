require "pp"

module Emerald
  class Interpreter
    attr_reader :global_env, :file, :had_error, :exit_on_error, :runtime
    def initialize(exit_on_error: true)
      @global_env = Environment.new(file: nil)
      @scoped_locals = {}
      @had_error = false
      @exit_on_error = exit_on_error

      @runtime = Emerald::Runtime.new
      runtime.define_builtins(global_env)
    end

    def had_error?
      had_error
    end

    def interprete(file)
      clear_error
      tokens = Emerald::Scanner.new(file).tokens
      ast = Emerald::Parser.new(file, tokens).parse
      ast, locals = Emerald::Resolver.new(file, ast).resolve_locals
      @scoped_locals = locals
      global_env.file = file
      interprete_node(ast, global_env)
    rescue Emerald::Error => e
      handle_error e
    end

    private

    attr_reader :scoped_locals

    EM_TRUE = Emerald::Types::TRUE
    EM_FALSE = Emerald::Types::FALSE
    EM_NIL = Emerald::Types::NIL
    def interprete_node(node, env)
      env.current_offset = node.offset
      case node.type
      when :block
        return nil if node.children.size == 0
        node.children.map do |node|
          interprete_node(node, env)
        end.last
      when :integer then Emerald::Types::Integer.new(node.child.to_i)
      when :string then Emerald::Types::String.new(node.child)
      when :symbol then Emerald::Types::Symbol.new(node.child.to_sym)
      when :identifier
        result =
          if (scope_distance = scoped_locals[node])
            env.get_at_distance(scope_distance, node.child)
          else
            global_env.get(node.child)
          end
        if result.is_a?(Emerald::Types::Function)
          result[env]
        else
          result
        end
      when :true then EM_TRUE
      when :false then EM_FALSE
      when :nil then EM_NIL
      when :def
        (_, (_, ident), value_node) = node
        value = interprete_node(value_node, env)
        env.set(ident, value)
        ident
      when :call
        (_, fn, *args) = node
        fn = interprete_node(s(:ref, fn), env)
        case fn
        when Emerald::Types::Function
          if args.length > 0
            args = args.map { |arg| interprete_node(arg, env) }
            fn.call(env, *args)
          else
            fn.call(env)
          end
        when Emerald::Types::Symbol
          callee = interprete_node(args[0], env)
          callee[fn]
        else
          fn
        end
      when :array
        Emerald::Types::Array.new(node.children.map { |e| interprete_node(e, env) })
      when :hashmap
        Emerald::Types::Hashmap.new(node.children.map { |e| interprete_node(e, env) })
      when :fn
        (_, params, body) = node
        define_function(env, "anonymous", params, body)
      when :defn
        (_, (_, name), params, body) = node
        fn = define_function(env, name, params, body)
        env.set name, fn
      when :guards
        (_, *guards) = node
        matching_guard = guards.detect do |(_, condition, _body)|
          interprete_node(condition, env)
        end
        unless matching_guard
          raise Emerald::NoMatchingGuardError.new(
            "No guard matched",
            env.file,
            env.current_offset
          )
        end
        (_, _, body) = matching_guard
        interprete_node(body, env)
      when :if
        (_, condition, body, else_body) = node
        if truthy?(interprete_node(condition, env))
          interprete_node(body, env)
        else
          else_body.any? ? interprete_node(else_body, env) : EM_NIL
        end
      when :unless
        (_, condition, body, else_body) = node
        # standard:disable Style/UnlessElse
        unless truthy?(interprete_node(condition, env))
          interprete_node(body, env)

        else
          else_body.any? ? interprete_node(else_body, env) : EM_NIL
        end
        # standard:enable Style/UnlessElse
      when :constant
        env.get_constant(node.child)
      when :deftype
        (_, (_, type_name), supertype) = node
        if env.get_constant(type_name, raise_if_not_exists: false)
          raise Emerald::NameError.new(
            "type #{type_name} is already defined",
            env.file,
            env.current_offset
          )
        end
        supertype = interprete_node(supertype, env)
        supertype = Emerald::Types::Base if is_nil?(supertype)
        new_type = Class.new(supertype)
        new_type.include(Emerald::Types::BaseClassMethods)
        Emerald::Types.const_set(type_name, new_type)
        global_env.set_constant type_name, new_type
        new_type
      when :ref
        (_, referred_value) = node
        case referred_value.type
        when :identifier
          env.get(referred_value.child)
        when :constant
          env.get_constant(referred_value.child)
        end
      else
        raise Emerald::NotImplementedError.new(
          "evaluation of :#{node.type} is not implemented",
          env.file,
          env.current_offset
        )
      end
    rescue Emerald::Error => e
      if e.file.nil? || e.offset.nil?
        raise e.class.new(e.message, env.file, env.current_offset)
      else
        raise
      end
    end

    def define_function(defining_env, name, params, body)
      arity = params.children.size
      Emerald::Types::Function.new(name, arity, proc { |_calling_env, *args|
        block_env = Environment.new(
          params.children.zip(args).map { |((_, arg_name), arg_value)| [arg_name, arg_value] }.to_h,
          file: defining_env.file,
          outer: defining_env
        )
        block_env.current_offset = defining_env.current_offset
        result = interprete_node(body, block_env)
        result
      })
    end

    def truthy?(value)
      ![EM_NIL, EM_FALSE].include?(value)
    end

    def is_nil?(value)
      value == EM_NIL
    end

    def clear_error
      @had_error = false
    end

    def handle_error(e)
      @had_error = true
      $stderr.puts e.to_s # standard:disable Style/StderrPuts
      exit 1 if exit_on_error
    end
  end
end
