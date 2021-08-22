module Emerald
  module Types
    class Array
      class << self
        def define_builtins(env)
          env.set "map", -> (fn, arr) { arr.map { |el| fn[el] } }
        end
      end

      attr_reader :array
      def initialize(array)
        @array = array
      end

      def map
        Emerald::Types::Array.new(array.map { |el| yield el })
      end

      def inspect
        "[" + array.map(&:inspect).join(" ") +  "]"
      end
    end
  end
end
