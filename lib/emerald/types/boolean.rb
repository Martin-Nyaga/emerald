require "singleton"

module Emerald
  module Types
    module Boolean
      def self.from(value)
        if value
          True.instance
        else
          False.instance
        end
      end

      class True < Base
        include Singleton

        def to_s
          "true"
        end

        alias_method :inspect, :to_s
      end

      class False < Base
        include Singleton

        def to_s
          "false"
        end

        alias_method :inspect, :to_s
      end
    end
  end
end
