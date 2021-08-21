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
      while !eof? && match?(:newline)
        if result = expr
          ast << result
        end
      end
      ast
    end

    def expr
      call_expr || definition_expr || terminal_expr
    end

    def definition_expr
      if match?(:define)
        ident = consume!(:identifier, "Expected identifier, got #{current_text}")
        value = terminal_expr
        [:define, ident, value]
      end
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
      identifier_expr || integer_expr || parenthesized_expr || array_expr
    end

    def integer_expr
      return previous_token if match?(:integer)
    end

    def identifier_expr
      return previous_token if match?(:identifier)
    end

    def parenthesized_expr
      if match?(:left_round_bracket)
        ast = expr
        consume!(:right_round_bracket, "expected ), got #{current_text}")
        ast
      end
    end

    def array_expr
      if match?(:left_square_bracket)
        elements = []
        while result = terminal_expr
          elements << result
        end
        consume!(:right_square_bracket, "expected ], got #{current_text}")
        [:array, *elements]
      end
    end

  private
    def previous_token
      tokens[position - 1]
    end

    def current_token
      tokens[position]
    end

    def current_text
      '"' + current_token[1] + '"'
    end

    def match?(type)
      if check?(type)
        advance
        true
      else
        false
      end
    end

    def check?(type)
      return false if eof?
      current_token[0] == type
    end

    def advance
      return if eof?
      @position += 1
    end

    def consume!(type, message)
      assert_not_eof!
      raise SyntaxError.new(message) unless match?(type)
      previous_token
    end

    def eof?
      position == tokens.length
    end

    def assert_not_eof!
      raise SyntaxError.new("Unexpected end of input") if eof?
    end
  end
end
