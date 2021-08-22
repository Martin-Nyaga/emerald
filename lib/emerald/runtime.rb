module Emerald
  class Runtime
    def define_builtins(env)
      Math.define_builtins(env)
      IO.define_builtins(env)
    end

    class Math
      def self.define_builtins(env)
        env.set '+', Emerald::Types::Function.from_lambda('+', ->(a, b) { a + b })
        env.set '-', Emerald::Types::Function.from_lambda('+', ->(a, b) { a - b })
        env.set '/', Emerald::Types::Function.from_lambda('+', ->(a, b) { a / b })
        env.set '*', Emerald::Types::Function.from_lambda('+', ->(a, b) { a * b })
      end
    end

    class IO
      def self.define_builtins(env)
        env.set 'print', Emerald::Types::Function.from_lambda('print', ->(val) { print val.inspect; val })
        env.set 'println', Emerald::Types::Function.from_lambda('println', ->(val) { p val; val })
      end
    end
  end
end
