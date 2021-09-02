module Emerald
  module Types
    class String < Base
      attr_reader :str
      def initialize(str)
        @str = str
      end

      def ==(other)
        other.is_a?(self.class) && str == other.str
      end

      def_delegators :str, :to_s, :inspect
    end
  end
end
