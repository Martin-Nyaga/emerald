module Emerald
  module Types
    class Hashmap < Base
      attr_reader :hashmap

      def initialize(pairs)
        @hashmap = pairs.each_slice(2).to_a.map do |key, value|
          [key.to_key, value]
        end.to_h
      end

      def ==(other)
        Emerald::Types::Boolean.from(
          other.is_a?(self.class) && hashmap == other.hashmap
        )
      end

      def [](key)
        hashmap[key.to_key]
      end

      def to_s
        "{" + hashmap.to_a.flatten.map(&:inspect).join(" ") + "}"
      end
      alias_method :inspect, :to_s
    end
  end
end
