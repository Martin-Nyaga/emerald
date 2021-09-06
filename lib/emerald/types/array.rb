module Emerald
  module Types
    class Array < Base
      attr_reader :array

      def initialize(array)
        @array = array
      end

      def map
        Emerald::Types::Array.new(array.map { |el| yield el })
      end

      def ==(other)
        Emerald::Types::Boolean.from(
          other.is_a?(self.class) && array == other.array
        )
      end

      def to_s
        "[" + array.map(&:inspect).join(" ") + "]"
      end
    end
  end
end
