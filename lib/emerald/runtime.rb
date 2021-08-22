module Emerald
  class Runtime
    def define_builtins(env)
      Math.define_builtins(env)
      IO.define_builtins(env)
      Emerald::Types::Array.define_builtins(env)
    end

    class Math
      def self.define_builtins(env)
        env.set '+', Emerald::Types::Function.from_lambda('+', ->(a, b) { a + b })
        env.set '-', Emerald::Types::Function.from_lambda('-', ->(a, b) { a - b })
        env.set '/', Emerald::Types::Function.from_lambda('/', ->(a, b) { a / b })
        env.set '*', Emerald::Types::Function.from_lambda('*', ->(a, b) { a * b })
      end
    end

    class IO
      def self.define_builtins(env)
        env.set 'print', Emerald::Types::Function.from_lambda('print', ->(val) { print val.inspect; val })
        println_fn =
          Emerald::Types::Function.from_block('println', 0..1) do |arg|
            if arg then p arg else puts end
            arg
          end
        env.set 'println', println_fn
      end
    end
  end
end
