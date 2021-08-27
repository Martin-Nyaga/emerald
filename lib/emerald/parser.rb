module Emerald
  class Parser
    attr_reader :file, :tokens
    attr_accessor :position

    def initialize(file, tokens)
      @file = file
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
        raise Emerald::SyntaxError.new("Unexpected input #{current_text}", file, current_token[2])
      end
      ast.compact
    end

    def expr
      def_expr || defn_expr || fn_expr || if_expr || unless_expr || call_expr || terminal_expr
    end

    def def_expr
      if match?(:def)
        ident = consume!(:identifier, "identifier")
        value = require_expr!(terminal_expr, "expression")
        [:def, ident, value]
      end
    end

    def defn_expr
      if match?(:defn)
        ident  = require_expr!(identifier_expr, "identifier")
        params = parameters_expr
        body   = require_expr!(fn_body_expr, "function body")
        [:defn, ident, params, body]
      end
    end

    def fn_expr
      if match?(:fn)
        params = parameters_expr
        body   = require_expr!(fn_body_expr, "function body")
        [:fn, params, body]
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
        [require_expr!(expr, "body")]
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
        consume!(:end, "end")
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
        consume!(:end, "end")
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
      parenthesized_expr || array_expr || string_expr || symbol_expr
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
        consume!(:right_round_bracket, ")")
        ast
      end
    end

    def array_expr
      if match?(:left_square_bracket)
        elements = []
        while result = terminal_expr
          elements << result
        end
        consume!(:right_square_bracket, "]")
        [:array, *elements]
      end
    end

    def string_expr
      return previous_token if match?(:string)
    end

    def symbol_expr
      return previous_token if match?(:symbol)
    end

  private
    def previous_token
      tokens[position - 1]
    end

    def current_token
      return [:eof, "EOF", file.length - 1] if eof?
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

    def consume!(type, expected_text)
      assert_not_eof!
      raise SyntaxError.new(
        "Expected #{expected_text}, got #{current_text}",
        file,
        position
      ) unless match?(type)
      previous_token
    end

    def skip(type)
      while match?(type); end
    end

    def eof?
      position == tokens.length
    end

    def assert_not_eof!
      raise SyntaxError.new("Unexpected end of input", file, file.length - 1) if eof?
    end

    def require_expr!(expr, expected_text)
      raise SyntaxError.new(
        "Expected #{expected_text}, got #{current_text}",
        file,
        position
      ) if expr.nil?
      expr
    end
  end
end
