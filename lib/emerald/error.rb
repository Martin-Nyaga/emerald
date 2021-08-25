module Emerald
  class Error < StandardError
    attr_reader :message, :file, :offset

    def initialize(message, file, offset)
      @message = message
      @file = file
      @offset = offset
    end

    def to_s
      error_string =  name_and_message + "\n"
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
      text = "in #{file.path} on line #{line_number}"
      indent(text, amount: indentation)
    end

    def context
      text = file.context_around(offset: offset, line_number: line_number)
      indent(text, amount: indentation)
    end

    # TODO: Add backtrace
    def formatted_backtrace
      ""
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
end
