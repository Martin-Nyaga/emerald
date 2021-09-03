module Emerald
  module Types
    class Nil < Base
      include Singleton

      def to_s
        "nil"
      end

      alias_method :inspect, :to_s
    end
  end
end
