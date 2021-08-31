module Emerald
  module Types
    class Symbol < Base
      attr_reader :sym
      def initialize(sym)
        @sym = sym
      end

      def ==(other)
        other.is_a?(self.class) && self.sym == other.sym
      end

      def to_key
        sym
      end

      def_delegators :sym, :to_s, :inspect
    end
  end
end
