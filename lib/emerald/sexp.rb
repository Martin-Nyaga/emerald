require "forwardable"

module Emerald
  class Sexp
    extend Forwardable

    def_delegators :array, :<<

    def initialize(*array, offset:)
      @array = array
      @offset = offset
    end

    def to_ary
      array
    end

    def offset
      return @offset unless @offset.nil?
      return array[1].offset if array.length >= 2
      nil
    end

    def ==(other)
      return false unless other.is_a?(Sexp)
      array == other.array && offset == other.offset
    end

    def match?(some_type)
      type == some_type
    end

    def type
      array[0]
    end

    def inspect
      elements = array.map(&:inspect).join(", ")
      elements += ", " if elements.length > 0
      "s(#{elements}offset: #{offset})"
    end

    def children
      array[1..-1]
    end

    def child(i = 0)
      children[i]
    end

    def any?
      children.any?
    end

    def compact!
      array.compact!
      self
    end

    protected

    attr_reader :array

    class OffsetError < StandardError; end
  end
end

class Object
  def s(*array, offset: nil)
    Emerald::Sexp.new(*array, offset: offset)
  end
end
