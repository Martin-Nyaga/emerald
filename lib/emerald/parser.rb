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
      if !eof?
        raise SyntaxError.new("Unexpected input #{current_text}")
      end
      ast
    end

    def expr
      def_expr || defn_expr || fn_expr || if_expr || unless_expr || call_expr || terminal_expr
    end

    def def_expr
      if match?(:def)
        ident = consume!(:identifier, "Expected identifier, got #{current_text}")
        value = terminal_expr
        [:def, ident, value]
      end
    end

    def defn_expr
      if match?(:defn)
        [:defn, identifier_expr, parameters_expr, fn_body_expr]
      end
    end

    def fn_expr
      if match?(:fn)
        [:fn, parameters_expr, fn_body_expr]
      end
    end

    def parameters_expr
      ast = []
      while result = identifier_expr
        ast << result
      end
      ast
    end

    def fn_body_expr
      single_line_body_expr || multiline_body_expr
    end

    def single_line_body_expr
      if match?(:arrow)
        [expr]
      end
    end

    def multiline_body_expr
      if match?(:do)
        ast = []
        skip(:newline)
        while result = expr
          skip(:newline)
          ast << result
        end
        skip(:newline)
        consume!(:end, "Expected end, got #{current_text}")
        ast
      end
    end

    def multiline_body_with_possible_else_expr
      if match?(:do)
        default_branch = []
        skip(:newline)
        while result = expr
          skip(:newline)
          default_branch << result
        end
        skip(:newline)
        else_branch = []
        if match?(:else)
          skip(:newline)
          while result = expr
            skip(:newline)
            else_branch << result
          end
        end
        skip(:newline)
        consume!(:end, "Expected end, got #{current_text}")
        [default_branch, else_branch]
      end
    end

    def if_expr
      condition_expr(:if)
    end

    def unless_expr
      condition_expr(:unless)
    end

    def condition_expr(matcher)
      if match?(matcher)
        condition = terminal_expr || call_expr
        if result = single_line_body_expr
          true_branch = result
          false_branch = []
        else
          (true_branch, false_branch) = multiline_body_with_possible_else_expr
        end
        [matcher, condition, true_branch, false_branch]
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
      identifier_expr || boolean_expr || nil_expr || integer_expr ||
      parenthesized_expr || array_expr || string_expr
    end

    def boolean_expr
      return [previous_token.first] if match?(:true) || match?(:false)
    end

    def nil_expr
      return [previous_token.first] if match?(:nil)
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

    def string_expr
      return previous_token if match?(:string)
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

    def skip(type)
      while match?(type); end
    end

    def eof?
      position == tokens.length
    end

    def assert_not_eof!
      raise SyntaxError.new("Unexpected end of input") if eof?
    end
  end
end
