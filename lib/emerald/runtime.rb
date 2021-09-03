module Emerald
  class Runtime
    def define_builtins(env)
      env.set_constant "Type", Emerald::Types::Type
      env.set_constant "String", Emerald::Types::String
      env.set_constant "Array", Emerald::Types::Array
      env.set_constant "Hashmap", Emerald::Types::Hashmap
      env.set_constant "Integer", Emerald::Types::Integer
      env.set_constant "Symbol", Emerald::Types::Symbol
      env.set_constant "Boolean", Emerald::Types::Boolean
      env.set_constant "Nil", Emerald::Types::Nil
      env.set_constant "Function", Emerald::Types::Function
      env.set_constant "Error", Emerald::Types::Error

      # Math
      [:+, :-, :*, :/, :>, :>=, :<, :<=, :==, :%].each do |op|
        define_function(env, op.to_s, 2) do |env, a, b|
          a.send(op, b)
        end
      end

      # IO
      define_function(env, "print", 0..) do |env, *vals|
        print(*vals)
        Emerald::Types::NIL
      end

      define_function(env, "println", 0..) do |env, *args|
        if args.length > 0
          print(*args)
        end
        puts
        Emerald::Types::NIL
      end

      # Array
      define_function(env, "map", 2) do |env, fn, arr|
        arr.map { |el| fn.call(env, el) }
      end

      # hashmap
      define_function(env, "get", 2) do |env, hashmap, key|
        hashmap[key]
      end

      # Error
      define_function(env, "raise", 1..2) do |env, error_type, message = Emerald::Types::String.new("Runtime error")|
        raise error_type.new.ruby_error_class.new(message.str, env.file, env.current_offset)
      end

      # Type
      define_function(env, "type", 1) do |env, value|
        if value.is_a?(Class)
          Emerald::Types::Type.new(Emerald::Types::Type)
        else
          Emerald::Types::Type.new(value.class)
        end
      end

      define_function(env, "super", 1) do |env, value|
        if value.is_a?(Class)
          Emerald::Types::Type.new(Class.superclass)
        else
          Emerald::Types::Type.new(value.class.superclass)
        end
      end
    end

    def define_function(env, name, arity, &block)
      env.set name, Emerald::Types::Function.new(name, arity, block)
    end
  end
end
