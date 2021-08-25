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
        @arity = Arity.new(arity)
      end

      def call(*args)
        raise ArgumentError, <<~MSG.strip unless arity.valid?(args.count)
          Invalid number of arguments, expected #{arity.inspect}, got #{args.count}
        MSG

        callable.call(*args)
      end
      alias [] call

      def inspect
        "<fn: #{name} (#{arity.inspect})>"
      end

      class Arity
        def initialize(arity)
          @arity = arity.is_a?(Range) ? arity : arity..arity
        end

        def valid?(args_count)
          arity.cover?(args_count)
        end

        def inspect
          one? ? arity.first.inspect : arity.inspect
        end

        private
          attr_reader :arity

          def one?
            arity.begin == arity.end
          end
      end
    end
  end
end
