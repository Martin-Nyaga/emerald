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

      env.set "type", (Emerald::Types::Function.from_block('type', 1) do |env, value|
        if value.is_a?(Class)
          Emerald::Types::Type.new(Emerald::Types::Type)
        else
          Emerald::Types::Type.new(value.class)
        end
      end)

      Math.define_builtins(env)
      IO.define_builtins(env)
      Emerald::Types::Array.define_builtins(env)
      Emerald::Types::Hashmap.define_builtins(env)
      Emerald::Types::Error.define_builtins(env)
    end

    class Math
      def self.define_builtins(env)
        [:+, :-, :*, :/, :>, :>=, :<, :<=, :==, :%].each do |op|
          env.set op.to_s,
            Emerald::Types::Function.from_lambda(op.to_s, ->(env, a, b) {
              a.send(op, b)
            })
        end
      end
    end

    class IO
      def self.define_builtins(env)
        env.set 'print', (Emerald::Types::Function.from_block('print', 0..) do |env, *vals|
           print *vals
           Emerald::Types::NIL
        end)

        env.set 'println', (Emerald::Types::Function.from_block('println', 0..) do |env, *args|
          if args.length > 0
            print *args
            puts
          else
            puts
          end
           Emerald::Types::NIL
        end)
      end
    end
  end
end
