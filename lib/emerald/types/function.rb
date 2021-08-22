module Emerald
  module Types
    class Function
      class << self
        def from_block(name, arity, &block)
          new(name, arity, block)
        end

        def from_lambda(name, _lambda)
          new(name, _lambda.arity, _lambda)
        end
      end

      attr_reader :name, :arity, :callable

      def initialize(name, arity, callable)
        @name = name
        @callable = callable
        @arity = arity
      end

      def call(*args)
        raise ArgumentError, <<~MSG.strip unless args.count == arity
          Invalid number of arguments, expected #{arity}, got #{args.count}
        MSG

        callable.call(*args)
      end
      alias [] call

      def inspect
        "<fn: #{name}>"
      end
    end
  end
end
