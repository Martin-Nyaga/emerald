module Emerald
  module Types
    class Error
      class << self
        def define_builtins(env)
          env.set "raise",
            (Emerald::Types::Function.from_block("raise", (1..2)) do |env, error_type, message = Emerald::Types::String.new("Runtime error")|
              raise error_type.new.ruby_error_class.new(message.str, env.file, env.current_offset)
            end)
        end
      end

      attr_reader :ruby_error_class
      def initialize(ruby_error_class = Emerald::Error)
        @ruby_error_class = ruby_error_class
      end
    end
  end
end
