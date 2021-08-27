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
      ast = s(:block)
      ast << expr
      while !eof? && match?(:newline)
        if result = expr
          ast << result
        end
      end
      if !eof?
        raise Emerald::SyntaxError.new(
          "Unexpected input #{current_text}",
          file,
          current_token.offset
        )
      end
      ast.compact!
    end

    def expr
      def_expr || defn_expr || fn_expr || if_expr || unless_expr || call_expr || terminal_expr
    end

    def def_expr
      if match?(:def)
        ident = consume!(:identifier, "identifier")
        value = require_expr!(terminal_expr, "expression")
        s(:def, ident, value)
      end
    end

    def defn_expr
      if match?(:defn)
        ident  = require_expr!(identifier_expr, "identifier")
        params = parameters_expr
        body   = require_expr!(fn_body_expr, "function body")
        s(:defn, ident, params, body)
      end
    end

    def fn_expr
      if match?(:fn)
        params = parameters_expr
        body   = require_expr!(fn_body_expr, "function body")
        s(:fn, params, body)
      end
    end

    def parameters_expr
      ast = s(:params)
      while result = identifier_expr
        ast << result
      end
      ast
    end

    def fn_body_expr
      guarded_body_expr || single_line_body_expr || multiline_body_expr
    end

    def single_line_body_expr
      if match?(:arrow)
        s(:block, require_expr!(expr, "body"))
      end
    end

    def multiline_body_expr
      if match?(:do)
        ast = s(:block)
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

    def guarded_body_expr
      if check?(:when) || look_over(:newline).match?(:when)
        ast = s(:guards)
        while check?(:when) || look_over(:newline).match?(:when)
          skip(:newline)
          ast << require_expr!(when_expr, "when expression")
        end
        skip(:newline)
        consume!(:end, "end")
        ast
      end
    end

    def when_expr
      if match?(:when)
        ast = s(:when)
        ast << require_expr!(when_condition_expr, "when condition")
        ast << require_expr!(when_body_expr, "when body")
        ast
      end
    end

    def when_condition_expr
      call_expr
    end

    def when_body_expr
      single_line_body_expr || multiline_body_expr
    end

    def multiline_body_with_possible_else_expr
      if match?(:do)
        default_branch = s(:block)
        skip(:newline)
        while result = expr
          skip(:newline)
          default_branch << result
        end
        skip(:newline)
        else_branch = s(:block)
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
          false_branch = s(:block)
        else
          (true_branch, false_branch) = multiline_body_with_possible_else_expr
        end
        s(matcher, condition, true_branch, false_branch)
      end
    end

    def call_expr
      if match?(:identifier)
        ident = previous_token
        args = args_expr
        s(:call, ident, *args)
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
      return previous_token if match?(:true) || match?(:false)
    end

    def nil_expr
      return previous_token if match?(:nil)
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
        s(:array, *elements)
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
      return eof_token if eof?
      tokens[position]
    end

    def eof_token
      s(:eof, "EOF", offset: file.length - 1)
    end

    def current_text
      '"' + current_token.children[0] + '"'
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
      current_token.match?(type)
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

    def look_ahead(n = 1)
      if position + 1 < tokens.length
        tokens[position + n]
      else
        eof_token
      end
    end

    def look_over(type)
      n = 1
      while look_ahead(n).match?(type)
        n += 1
      end
      return look_ahead(n)
    end

    def assert_not_eof!
      raise Emerald::SyntaxError.new("Unexpected end of input", file, file.length - 1) if eof?
    end

    def require_expr!(expr, expected_text)
      raise Emerald::SyntaxError.new(
        "Expected #{expected_text}, got #{current_text}",
        file,
        position
      ) if expr.nil?
      expr
    end
  end
end
