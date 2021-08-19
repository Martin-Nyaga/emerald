module Emerald
  class Runtime
    def define_builtins(env)
      Math.new.define_builtins(env)
    end

    class Math
      def define_builtins(env)
        env["+"] = Function.new("+", -> (a, b) { a + b })
        env["-"] = Function.new("+", -> (a, b) { a - b })
        env["/"] = Function.new("+", -> (a, b) { a / b })
        env["*"] = Function.new("+", -> (a, b) { a * b })
      end
    end

    class Function
      attr_reader :name, :callable, :arity
      def initialize(name, callable)
        @name = name
        @callable = callable
        @arity = callable.arity
      end

      def call(*args)
        raise ArgumentError.new <<~MSG.strip unless args.count == arity
          Invalid number of arguments, expected #{arity}, got #{args.count}
        MSG
        callable.call(*args)
      end
      alias :[] :call
    end
  end
end
