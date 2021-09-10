module Emerald
  module Types
    class Error < Base
      attr_reader :message

      class << self
        def constructable?
          true
        end
      end

      def initialize(env, args)
        message = args[0] || Emerald::Types::String.new("Runtime error")
        Emerald::Types.assert_type(env, message, Emerald::Types::String)
        @message = message
        @error = self.class.name
      end

      def ruby_error(env)
        Emerald::Error.new(
          message.str,
          env.file,
          env.current_offset,
          env.stack_frames
        )
      end
    end
  end
end
