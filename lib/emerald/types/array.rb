module Emerald
  module Types
    class Array
      class << self
        def define_builtins(env)
          env.set("map",
            Emerald::Types::Function.from_block("map", 2) do |file, node, fn, arr|
              arr.map { |el| fn.call(file, node, el) }
            end)
        end
      end

      attr_reader :array
      def initialize(array)
        @array = array
      end

      def map
        Emerald::Types::Array.new(array.map { |el| yield el })
      end

      def ==(other)
        array == other.array
      end

      def to_s
        "[" + array.map(&:to_s).join(" ") +  "]"
      end
      alias inspect to_s
    end
  end
end
