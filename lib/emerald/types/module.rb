module Emerald
  module Types
    class Module
      attr_reader :env
      def initialize(env)
        @env = env
      end
    end
  end
end
