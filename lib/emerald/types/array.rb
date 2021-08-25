module Emerald
  module Types
    class Array
      class << self
        def define_builtins(env)
          env.set "map", Emerald::Types::Function.from_lambda("map", -> (fn, arr) { arr.map { |el| fn[el] } })
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
