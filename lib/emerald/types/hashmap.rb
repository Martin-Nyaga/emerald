module Emerald
  module Types
    class Hashmap
      class << self
        def define_builtins(env)
          env.set "get",
            (Emerald::Types::Function.from_block("get", 2) do |env, hashmap, key|
              hashmap[key]
            end)
        end
      end

      attr_reader :hashmap

      def initialize(pairs)
        @hashmap = pairs.each_cons(2).to_a.map do |key, value|
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
