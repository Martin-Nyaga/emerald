module Emerald
  module Types
    class Array
      attr_reader :array
      def initialize(array)
        @array = array
      end

      def inspect
        "[" + array.map(&:inspect).join(" ") +  "]"
      end
    end
  end
end
