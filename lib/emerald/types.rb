require "forwardable"

module Emerald
  module Types
    class Base
      extend Forwardable

      def assert_type(arg, type, message)
        raise Emerald::TypeError.new(message) unless arg.is_a?(type)
      end
    end

    class Type < Base
      attr_reader :type

      def initialize(type)
        @type = type
      end

      def ==(other)
        other.is_a?(self.class) && self.type == other.type
      end

      def_delegators :type, :to_s, :inspect
    end

    autoload :Array, "emerald/types/array"
    autoload :Function, "emerald/types/function"
    autoload :Hashmap, "emerald/types/hashmap"
    autoload :Integer, "emerald/types/integer"
    autoload :String, "emerald/types/string"
    autoload :Symbol, "emerald/types/symbol"
    autoload :Boolean, "emerald/types/boolean"
    autoload :Nil, "emerald/types/nil"

    TRUE = Emerald::Types::Boolean::True.instance
    FALSE = Emerald::Types::Boolean::False.instance
    NIL = Emerald::Types::Nil.instance
  end
end
