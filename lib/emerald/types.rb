require "forwardable"

module Emerald
  module Types
    autoload :Array, "emerald/types/array"
    autoload :Function, "emerald/types/function"
    autoload :Hashmap, "emerald/types/hashmap"
    autoload :Integer, "emerald/types/integer"
    autoload :String, "emerald/types/string"
    autoload :Symbol, "emerald/types/symbol"
    autoload :Boolean, "emerald/types/boolean"
    autoload :Nil, "emerald/types/nil"
    autoload :Error, "emerald/types/error"

    module BaseClassMethods
      module ClassMethods
        def to_s
          name.delete_prefix("Emerald::Types::")
        end
      end

      def self.included(base)
        base.extend ClassMethods
      end
    end

    module UserDefinedTypeClassMethods
      module ClassMethods
        def constructable?
          true
        end
      end

      def self.included(base)
        base.extend ClassMethods
      end
    end

    class Base
      extend Forwardable
      include BaseClassMethods

      def self.inherited(klass)
        klass.include(BaseClassMethods)
      end

      def self.constructable?
        false
      end

      def assert_type(env, arg, type, message = nil)
        unless arg.is_a?(type)
          raise Emerald::TypeError.new(
            message || "expected #{type} got #{arg.class}",
            env.file,
            env.current_offset,
            env.stack_frames
          )
        end
      end

      def to_key
        inspect
      end
    end

    TRUE = Emerald::Types::Boolean::True.instance
    FALSE = Emerald::Types::Boolean::False.instance
    NIL = Emerald::Types::Nil.instance
  end
end
