require "pp"
require "pathname"

module Emerald
  class Interpreter
    attr_reader :global_env, :file, :had_error, :exit_on_error, :runtime
    def initialize(exit_on_error: true)
      @global_env = Environment.new(file: nil)
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
      tokens = Emerald::Lexer.new(file).tokens
      ast = Emerald::Parser.new(file, tokens).parse
      ast, locals = Emerald::Resolver.new(file, ast).resolve_locals
      global_env.scoped_locals = locals
      global_env.file = file
      interprete_node(ast, global_env)
    rescue Emerald::Error => e
      handle_error e
    end

    private

    EM_TRUE = Emerald::Types::TRUE
    EM_FALSE = Emerald::Types::FALSE
    EM_NIL = Emerald::Types::NIL

    def interprete_node(node, env)
      env.current_offset = node.offset
      send("interprete_#{node.type}", node, env)
    rescue NoMethodError
      # FIXME: check for existence of the method so we don't overwrite other
      # legitimate NoMethodErrors
      raise Emerald::NotImplementedError.new(
        "evaluation of :#{node.type} is not implemented",
        env.file,
        env.current_offset,
        env.stack_frames
      )
    end

    def interprete_block(node, env)
      return nil if node.children.size == 0
      node.children.map do |node|
        interprete_node(node, env)
      end.last
    end

    def interprete_integer(node, env)
      Emerald::Types::Integer.new(node.child.to_i)
    end

    def interprete_string(node, env)
      Emerald::Types::String.new(node.child)
    end

    def interprete_symbol(node, env)
      Emerald::Types::Symbol.new(node.child.to_sym)
    end

    def interprete_identifier(node, env)
      result =
        if (scope_distance = global_env.scoped_locals[node])
          env.get_at_distance(scope_distance, node.child)
        else
          global_env.get(node.child)
        end
      if result.is_a?(Emerald::Types::Function)
        result[env]
      else
        result
      end
    end

    def interprete_true(node, env)
      EM_TRUE
    end

    def interprete_false(node, env)
      EM_FALSE
    end

    def interprete_nil(node, env)
      EM_NIL
    end

    def interprete_def(node, env)
      (_, (_, ident), value_node) = node
      value = interprete_node(value_node, env)
      env.set(ident, value)
      ident
    end

    def interprete_call(node, env)
      (_, fn, *args) = node
      case fn.type
      when :identifier
        fn = interprete_node(s(:ref, fn), env)
        if fn.is_a?(Emerald::Types::Function)
          if args.length > 0
            args = args.map { |arg| interprete_node(arg, env) }
            env.current_offset = node.offset
            fn.call(env, *args)
          else
            fn.call(env)
          end
        end
      when :symbol
        fn = interprete_node(fn, env)
        callee = interprete_node(args[0], env)
        callee[env, fn]
      else
        fn
      end
    end

    def interprete_array(node, env)
      Emerald::Types::Array.new(node.children.map { |e| interprete_node(e, env) })
    end

    def interprete_hashmap(node, env)
      Emerald::Types::Hashmap.new(node.children.map { |e| interprete_node(e, env) })
    end

    def interprete_fn(node, env)
      (_, params, body) = node
      define_function(env, "anonymous", params, body)
    end

    def interprete_defn(node, env)
      (_, (_, name), params, body) = node
      fn = define_function(env, name, params, body)
      env.set name, fn
    end

    def interprete_guards(node, env)
      (_, *guards) = node
      matching_guard = guards.detect do |(_, condition, _body)|
        interprete_node(condition, env) == EM_TRUE
      end
      unless matching_guard
        raise Emerald::NoMatchingGuardError.new(
          "No guard matched",
          env.file,
          env.current_offset,
          env.stack_frames
        )
      end
      (_, _, body) = matching_guard
      interprete_node(body, env)
    end

    def interprete_if(node, env)
      (_, condition, body, else_body) = node
      if truthy?(interprete_node(condition, env))
        interprete_node(body, env)
      else
        else_body.any? ? interprete_node(else_body, env) : EM_NIL
      end
    end

    def interprete_unless(node, env)
      (_, condition, body, else_body) = node
      # standard:disable Style/UnlessElse
      unless truthy?(interprete_node(condition, env))
        interprete_node(body, env)

      else
        else_body.any? ? interprete_node(else_body, env) : EM_NIL
      end
      # standard:enable Style/UnlessElse
    end

    def interprete_deftype(node, env)
      (_, (_, type_name), supertype, fields) = node
      if env.get_constant(type_name, raise_if_not_exists: false)
        raise Emerald::NameError.new(
          "type #{type_name} is already defined",
          env.file,
          env.current_offset,
          env.stack_frames
        )
      end
      supertype =
        if supertype.type == :nil
          Emerald::Types::Base
        else
          interprete_node(s(:ref, supertype), env)
        end
      new_type = Class.new(supertype)
      new_type.include(Emerald::Types::BaseClassMethods)
      new_type.include(Emerald::Types::UserDefinedTypeClassMethods)

      fields = interprete_node(fields, env)
      fields.each do |field|
        Emerald::Types.assert_type(env, field, Emerald::Types::Symbol)
      end
      new_type.add_fields(fields.array)

      Emerald::Types.const_set(type_name, new_type)
      env.set_constant type_name, new_type
      new_type
    end

    def interprete_ref(node, env)
      (_, referred_value) = node
      case referred_value.type
      when :identifier
        env.get(referred_value.child)
      when :constant
        env.get_constant(referred_value.child)
      end
    end

    def interprete_constructor(node, env)
      (_, (_, type_name), *args) = node
      type = env.get_constant(type_name)
      if type.constructable?
        if args.length > 0
          args = args.map { |arg| interprete_node(arg, env) }
          if args.length == 1 && args[0].is_a?(Emerald::Types::Hashmap)
            type.new(env, args[0])
          else
            type.new(env, args)
          end
        else
          type.new(env)
        end
      else
        raise Emerald::TypeError.new(
          "Type `#{type_name}` is not constructable",
          env.file,
          env.current_offset,
          env.stack_frames
        )
      end
    end

    STDLIB_PATH = File.join(File.expand_path(__dir__), "../../emerald/lib")
    def interprete_import(node, env)
      (_, (_, path)) = node
      path_with_extension = Pathname.new(path).sub_ext(".em")
      candidates = Dir[File.join(STDLIB_PATH, path_with_extension)] + Dir[path_with_extension]
      unless candidates.any?
        raise Emerald::LoadError.new(
          "Could not find file: #{path}",
          env.file,
          env.current_offset,
          env.stack_frames
        )
      end
      target_file = Emerald::Files::RealFile.new(candidates.first)

      tokens = Emerald::Lexer.new(target_file).tokens
      ast = Emerald::Parser.new(target_file, tokens).parse
      ast, locals = Emerald::Resolver.new(target_file, ast).resolve_locals
      file_env = Environment.new(file: target_file, outer: global_env, scoped_locals: locals)
      interprete_node(ast, file_env)
      # FIXME: This is a hack
      global_env.env.merge!(file_env.env)
      EM_NIL
    end

    def interprete_defmodule(node, env)
      (_, (_, module_name), module_body) = node
      module_env = Environment.new(outer: env)
      interprete_node(module_body, module_env)
      module_constant = Emerald::Types::Module.new(module_env)
      env.set_constant module_name, module_constant
      module_constant
    end

    def define_function(defining_env, name, params, body)
      arity = params.children.size
      Emerald::Types::Function.new(name, arity, proc { |calling_env, *args|
        block_env = Environment.new(
          env: params.children.zip(args).map { |((_, arg_name), arg_value)| [arg_name, arg_value] }.to_h,
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
