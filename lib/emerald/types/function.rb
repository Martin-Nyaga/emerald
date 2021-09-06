module Emerald
  module Types
    class Function < Base
      attr_reader :name, :arity, :callable

      def initialize(name, arity, callable)
        @name = name
        @callable = callable
        @arity = Arity.new(arity)
      end

      def call(env, *args)
        unless arity.valid?(args.count)
          raise Emerald::ArgumentError.new(
            "Invalid number of arguments for #{inspect}, expected #{arity.inspect}, got #{args.count}",
            env.file,
            env.current_offset
          )
        end

        callable.call(env, *args)
      end
      alias_method :[], :call

      def to_s
        "<fn: #{name} (#{arity.inspect})>"
      end
      alias_method :inspect, :to_s

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
