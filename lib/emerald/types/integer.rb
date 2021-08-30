module Emerald
  module Types
    class Integer < Base
      attr_reader :int
      def initialize(int)
        @int = int
      end

      [:==, :>, :>=, :<, :<=].each do |method_name|
        define_method(method_name) do |other|
          Emerald::Types::Boolean.from(
            other.is_a?(self.class) && int == other.int
          )
        end
      end

      def_delegators :int, :to_s, :inspect

      [:+, :-, :*, :/, :%].each do |method_name|
        define_method(method_name) do |other|
          assert_type other, Integer, "#{other} cannot be coerced to #{self.class.name}"
          self.class.new int.send(method_name, other.int)
        end
      end
    end
  end
end
