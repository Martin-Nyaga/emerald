module Emerald
  module Types
    class Error < Base
      attr_reader :message

      def initialize(message)
        @message = message
      end

      def ruby_error(env)
        Emerald::Error.new(message.str, env.file, env.current_offset)
      end
    end
  end
end
