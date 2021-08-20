module Emerald
  class Parser
    attr_reader :tokens
    attr_accessor :position

    def initialize(tokens)
      @tokens = tokens
      @position = 0
    end

    def parse
      prog
    end

    def prog
      ast = []
      ast << expr
      while match?(:newline) && !eof?
        if result = expr
          ast << result
        else
          break
        end
      end
      ast
    end

    def expr
      call_expr || terminal_expr
    end

    def call_expr
      if match?(:identifier)
        ident = previous_token
        args = args_expr
        [:call, ident, *args]
      end
    end

    def args_expr
      ast = []
      while !eof? && result = terminal_expr
        ast << result
      end
      ast
    end

    def terminal_expr
      identifier_expr || integer_expr
    end

    def integer_expr
      return previous_token if match?(:integer)
    end

    def identifier_expr
      return previous_token if match?(:identifier)
    end

  private
    def previous_token
      tokens[position - 1]
    end

    def current_token
      tokens[position]
    end

    def match?(type)
      assert_not_eof!
      if current_token[0] == type
        advance
        true
      else
        false
      end
    end

    def advance
      assert_not_eof!
      @position += 1
    end

    def consume(type, message)
      raise SyntaxError.new(message) unless match(type)
    end

    def eof?
      position == tokens.length
    end

    def assert_not_eof!
      raise SyntaxError.new("Unexpected end of input") if eof?
    end
  end
end
