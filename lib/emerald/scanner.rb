require "set"

module Emerald
  class TokenType
    attr_reader :type, :pattern, :is_keyword, :match_extractor
    def initialize(type, pattern, is_keyword = false, &match_extractor)
      @type = type
      @pattern = pattern
      @is_keyword = is_keyword
      @match_extractor = match_extractor || ->(m) { m[0] }
    end

    def match(str, file, offset)
      if (match = pattern.match(str))
        Token.new(
          type,
          match,
          is_keyword,
          file,
          offset,
          match_extractor
        )
      end
    end
  end

  class Token
    attr_reader :type, :matchdata, :is_keyword, :file, :offset, :match_extractor
    def initialize(
      type,
      matchdata,
      is_keyword,
      file,
      offset,
      match_extractor
    )
      @type = type
      @matchdata = matchdata
      @is_keyword = is_keyword
      @file = file
      @offset = offset
      @match_extractor = match_extractor
    end

    def to_sexp
      s(type, text, offset: offset)
    end

    def length
      matchdata[0].length
    end

    def text
      match_extractor[matchdata]
    end

    def match_length_and_keyword_priority
      [length, is_keyword ? 1 : 0]
    end
  end

  TOKEN_TYPES = [
    # Keywords
    TokenType.new(:def, /\Adef/, true),
    TokenType.new(:defn, /\Adefn/, true),
    TokenType.new(:deftype, /\Adeftype/, true),
    TokenType.new(:do, /\Ado/, true),
    TokenType.new(:else, /\Aelse/, true),
    TokenType.new(:end, /\Aend/, true),
    TokenType.new(:false, /\Afalse/, true),
    TokenType.new(:fn, /\Afn/, true),
    TokenType.new(:if, /\Aif/, true),
    TokenType.new(:import, /\Aimport/, true),
    TokenType.new(:nil, /\Anil/, true),
    TokenType.new(:true, /\Atrue/, true),
    TokenType.new(:unless, /\Aunless/, true),
    TokenType.new(:when, /\Awhen/, true),

    # Other words
    TokenType.new(:identifier, /\A[+\-\/*%]|\A[><]=?|\A==|\A[a-z]+[a-zA-Z_0-9]*\??/),
    TokenType.new(:constant, /\A[A-Z]+[a-zA-Z_0-9]*/),
    TokenType.new(:integer, /\A[0-9]+/),
    TokenType.new(:string, /\A"([^"]*)"/) { _1[1] },
    TokenType.new(:symbol, /\A:([a-z]+[a-zA-Z_0-9]*\??)/) { _1[1] },

    # Punctuation
    TokenType.new(:comment, /\A#.*/),
    TokenType.new(:newline, /\A\n|\A[\r\n]/),
    TokenType.new(:left_paren, /\A\(/),
    TokenType.new(:right_paren, /\A\)/),
    TokenType.new(:left_bracket, /\A\[/),
    TokenType.new(:right_bracket, /\A\]/),
    TokenType.new(:left_brace, /\A\{/),
    TokenType.new(:right_brace, /\A\}/),
    TokenType.new(:arrow, /\A->/),
    TokenType.new(:ref, /\A&/),
    TokenType.new(:comma, /\A,/),
    TokenType.new(:space, /\A[ \t]/)
  ]

  SKIP_TOKENS = Set[:space, :comment, :comma]
  class Scanner
    attr_reader :file
    attr_accessor :src, :offset

    def initialize(file)
      @file = file
      @src = file.contents
      @offset = 0
    end

    def tokens
      result = []

      while src.length > 0
        token = sorted_matches.last
        raise_syntax_error unless token
        result << token.to_sexp unless SKIP_TOKENS.include?(token.type)
        self.src = src[token.length..]
        self.offset += token.length
      end

      result
    end

    private

    def sorted_matches
      TOKEN_TYPES.filter_map do |type|
        type.match(src, file, offset)
      end.sort_by(&:match_length_and_keyword_priority)
    end

    def raise_syntax_error
      raise Emerald::SyntaxError.new(
        "Unexpected input `#{src[0]}`",
        file,
        offset
      )
    end
  end
end
