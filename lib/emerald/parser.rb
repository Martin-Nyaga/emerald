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
      deftype_expr || def_expr || defn_expr || fn_expr || if_expr || unless_expr || call_expr || terminal_expr
    end

    def deftype_expr
      if match?(:deftype)
        offset = previous_token.offset
        type_name = consume!(:constant, "type name")
        s(:deftype, type_name, offset: offset)
      end
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
        ident = require_expr!(identifier_expr, "identifier")
        params = parameters_expr
        body = require_expr!(fn_body_expr, "function body")
        s(:defn, ident, params, body)
      end
    end

    def fn_expr
      if match?(:fn)
        params = parameters_expr
        body = require_expr!(fn_body_expr, "function body")
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
      if check_over?(:newline, for_type: :when)
        ast = s(:guards)
        while check_over?(:newline, for_type: :when) ||
            check_over?(:newline, for_type: :else)
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
      elsif match?(:else)
        # Rewrite `else` branch as `when true`
        ast = s(:when)
        ast << s(:true, "else", offset: previous_token.offset)
        ast << require_expr!(when_body_expr, "when body")
        ast
      end
    end

    def when_condition_expr
      call_expr || terminal_expr
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
        condition = call_expr || terminal_expr
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
      identifier_call_expr || symbol_call_expr
    end

    def identifier_call_expr
      if match?(:identifier)
        ident = previous_token
        args = args_expr
        s(:call, ident, *args)
      end
    end

    def symbol_call_expr
      if match?(:symbol)
        symbol = previous_token
        callee = symbol_callable_expr
        if callee
          s(:call, symbol, callee)
        else
          backtrack(1)
          nil
        end
      end
    end

    def symbol_callable_expr
      identifier_expr || hashmap_expr || parenthesized_expr
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
        parenthesized_expr || array_expr || hashmap_expr || string_expr ||
        symbol_expr || constant_expr
    end

    def boolean_expr
      return previous_token if match?(:true) || match?(:false)
    end

    def constant_expr
      return previous_token if match?(:constant)
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
      if match?(:left_paren)
        ast = expr
        consume!(:right_paren, ")")
        ast
      end
    end

    def array_expr
      if match?(:left_bracket)
        elements = []
        while result = terminal_expr
          elements << result
        end
        consume!(:right_bracket, "]")
        s(:array, *elements)
      end
    end

    def hashmap_expr
      if match?(:left_brace)
        pairs = []
        while pair = key_value_pair_expr
          key, value = pair
          pairs << key
          pairs << value
        end
        consume!(:right_brace, "}")
        s(:hashmap, *pairs)
      end
    end

    def key_value_pair_expr
      if key = terminal_expr
        value = require_expr!(terminal_expr, "value")
        [key, value]
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
      unless match?(type)
        raise SyntaxError.new(
          "Expected #{expected_text}, got #{current_text}",
          file,
          position
        )
      end
      previous_token
    end

    def skip(type)
      while match?(type); end
    end

    def eof?
      position == tokens.length
    end

    def backtrack(n)
      @position -= n
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
      look_ahead(n)
    end

    def check_over?(skipped_type, for_type:)
      check?(for_type) || look_over(skipped_type).match?(for_type)
    end

    def assert_not_eof!
      raise Emerald::SyntaxError.new("Unexpected end of input", file, file.length - 1) if eof?
    end

    def require_expr!(expr, expected_text)
      if expr.nil?
        raise Emerald::SyntaxError.new(
          "Expected #{expected_text}, got #{current_text}",
          file,
          position
        )
      end
      expr
    end
  end
end
