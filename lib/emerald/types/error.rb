module Emerald
  module Types
    class Error < Base
      attr_reader :ruby_error_class

      def initialize(ruby_error_class = Emerald::Error)
        @ruby_error_class = ruby_error_class
      end
    end
  end
end
