require "forwardable"

module Emerald
  class Sexp
    extend Forwardable

    def_delegators :array, :<<

    attr_accessor :offset

    def initialize(*array, offset:)
      @array = array
      @offset = offset.nil? ? array[1].offset : offset
    end

    def to_ary
      array
    end

    def ==(other)
      array = other.array && offset == other.offset
    end

    def inspect
      elements = array.map(&:inspect).join(", ")
      elements += ", " if elements.length > 0
      "s(#{elements}offset: #{offset})"
    end

    protected
    attr_reader :array
  end
end

class Object
  def s(*array, offset: nil)
    Emerald::Sexp.new(*array, offset: offset)
  end
end
