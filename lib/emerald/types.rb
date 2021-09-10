require "forwardable"

module Emerald
  module Types
    autoload :Base, "emerald/types/base"
    autoload :Array, "emerald/types/array"
    autoload :Function, "emerald/types/function"
    autoload :Hashmap, "emerald/types/hashmap"
    autoload :Integer, "emerald/types/integer"
    autoload :String, "emerald/types/string"
    autoload :Symbol, "emerald/types/symbol"
    autoload :Boolean, "emerald/types/boolean"
    autoload :Nil, "emerald/types/nil"
    autoload :Error, "emerald/types/error"

    TRUE = Emerald::Types::Boolean::True.instance
    FALSE = Emerald::Types::Boolean::False.instance
    NIL = Emerald::Types::Nil.instance

    def self.assert_type(env, arg, type, message = nil)
      unless arg.is_a?(type)
        raise Emerald::TypeError.new(
          message || "expected #{type} got #{arg.class}",
          env.file,
          env.current_offset,
          env.stack_frames
        )
      end
    end

  end
end
