module Emerald
  class Error < StandardError
    attr_reader :message, :file, :offset, :stack_frames

    def initialize(
      message,
      file = nil,
      offset = nil,
      stack_frames = []
    )
      @message = message
      @file = file
      @offset = offset
      @stack_frames = stack_frames
    end

    def to_s
      error_string = "\n"
      error_string << name_and_message + "\n"
      error_string << location + "\n\n"
      error_string << context + "\n"
      error_string << formatted_backtrace
    end

    private

    def line_number
      @line_number ||= file.line_number(offset)
    end

    def indentation
      4
    end

    def name_and_message
      name + ": " + message
    end

    def location
      text = "in #{file.path}:#{line_number}"
      indent(text, amount: indentation)
    end

    def context
      text = file.context_around(offset)
      indent(text, amount: indentation)
    end

    def formatted_backtrace
      frames = stack_frames.reverse.map(&:to_formatted_s).join("\n")
      indent(frames, amount: indentation)
    end

    def name
      self.class.name.delete_prefix("Emerald::")
    end

    def indent(text, amount:)
      padding = " " * amount
      text.split("\n").map do |line|
        padding + line
      end.join("\n")
    end
  end

  class SyntaxError < Error; end

  class ArgumentError < Error; end

  class NameError < Error; end

  class RuntimeError < Error; end

  class TypeError < Error; end

  class NotImplementedError < Error; end

  class NoMatchingGuardError < Error; end

  class LoadError < Error; end
end
