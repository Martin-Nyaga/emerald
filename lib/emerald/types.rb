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
  end
end
