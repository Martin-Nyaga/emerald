require "pp"

module Emerald
  class Interpreter
    attr_reader :global_env, :file, :had_error, :exit_on_error
    def initialize(exit_on_error: true)
      @global_env = Environment.new(file: nil)
      @had_error = false
      @exit_on_error = exit_on_error

      define_builtins
    end

    def had_error?
      had_error
    end

    def interprete(file)
      clear_error
      tokens = Emerald::Scanner.new(file).tokens
      ast = Emerald::Parser.new(file, tokens).parse

      global_env.file = file
      interprete_node(ast, global_env)
    rescue Emerald::Error => e
      handle_error e
    end

    private

    def define_builtins
      Emerald::Runtime.new.define_builtins(global_env)
      global_env.set "env", Emerald::Types::Function.from_lambda("env", -> (env) { pp env })
    end

    def interprete_node(node, env)
      env.current_offset = node.offset
      case node.type
      when :block
        return nil if node.children.size == 0
        node.children.map do |node|
          interprete_node(node, env)
        end.last
      when :integer then node.child.to_i
      when :string then node.child
      when :symbol then node.child.to_sym
      when :identifier then env.get(node.child)
      when :true then true
      when :false then false
      when :nil then nil
      when :def
        (_, (_, ident), value_node) = node
        value = interprete_node(value_node, env)
        env.set(ident, value)
        ident
      when :call
        (_, fn, *args) = node
        fn = interprete_node(fn, env)
        if fn.is_a?(Emerald::Types::Function)
          if args.length > 0
            args = args.map { |arg| interprete_node(arg, env) }
            fn.call(env, *args)
          else
            fn.call(env)
          end
        else
          fn
        end
      when :array
        Emerald::Types::Array.new(node.children.map { |e| interprete_node(e, env) })
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
        if interprete_node(condition, env)
          interprete_node(body, env)
        else
          else_body.any? ? interprete_node(else_body, env) : nil
        end
      when :unless
        (_, condition, body, else_body) = node
        unless interprete_node(condition, env)
          interprete_node(body, env)
        else
          else_body.any? ? interprete_node(else_body, env) : nil
        end
      else
        raise Emerald::NotImplementedError.new(
          "evaluation of :#{node.type} is not implemented",
          env.file,
          env.current_offset
        )
      end
    end

    def define_function(defining_env, name, params, body)
      arity = params.children.size
      Emerald::Types::Function.from_block(name, arity) do |_calling_env, *args|
        block_env = Environment.new(
          params.children.zip(args).map { |((_, arg_name), arg_value)| [arg_name, arg_value] }.to_h,
          file: defining_env.file,
          outer: defining_env
        )
        block_env.current_offset = defining_env.current_offset
        result = interprete_node(body, block_env)
        result
      end
    end

    def clear_error
      @had_error = false
    end

    def handle_error(e)
      @had_error = true
      STDERR.puts e.to_s
      exit 1 if exit_on_error
    end
  end
end
