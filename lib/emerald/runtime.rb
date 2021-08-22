module Emerald
  class Runtime
    def define_builtins(env)
      Math.define_builtins(env)
      IO.define_builtins(env)
    end

    class Math
      def self.define_builtins(env)
        env["+"] = Callable.new("+", -> (a, b) { a + b })
        env["-"] = Callable.new("+", -> (a, b) { a - b })
        env["/"] = Callable.new("+", -> (a, b) { a / b })
        env["*"] = Callable.new("+", -> (a, b) { a * b })
      end
    end

    class IO
      def self.define_builtins(env)
        env["print"] = Callable.new("print", -> (val) { print val.inspect; val })
        env["println"] = Callable.new("println", -> (val) { p val; val })
      end
    end

    class Callable
      attr_reader :name, :callable, :arity
      def initialize(name, callable, arity = callable.arity)
        @name = name
        @callable = callable
        @arity = arity
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
