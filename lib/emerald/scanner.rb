require "set"

module Emerald
  class Token
    attr_reader :type, :pattern, :keyword, :match_extractor
    def initialize(type, pattern, keyword = false, &match_extractor)
      @type            = type
      @pattern         = pattern
      @keyword         = keyword
      @match_extractor = match_extractor || -> (m) { m[0] }
    end

    def match(str)
      if match = pattern.match(str)
        return Match.new(type, match, keyword, match_extractor)
      else
        nil
      end
    end
  end

  class Match
    attr_reader :type, :matchdata, :keyword, :match_extractor
    def initialize(type, matchdata, keyword, match_extractor)
      @type            = type
      @matchdata       = matchdata
      @keyword         = keyword
      @match_extractor = match_extractor
    end

    def to_a
      [type, text]
    end

    def length
      matchdata[0].length
    end

    def text
      match_extractor[matchdata]
    end

    def match_length_and_keyword_priority
      [length, keyword ? 1 : 0]
    end
  end

  TOKEN_TYPES = [
    # Keywords
    Token.new(:def, /\Adef/, true),
    Token.new(:fn, /\Afn/, true),
    Token.new(:defn, /\Adefn/, true),
    Token.new(:do, /\Ado/, true),
    Token.new(:end, /\Aend/, true),
    Token.new(:true, /\Atrue/, true),
    Token.new(:false, /\Afalse/, true),
    Token.new(:nil, /\Anil/, true),
    Token.new(:if, /\Aif/, true),
    Token.new(:unless, /\Aunless/, true),
    Token.new(:else, /\Aelse/, true),

    Token.new(:identifier, /\A[\+\-\/\*]|\A[><]=?|\A==|\A[a-z]+[a-zA-Z_0-9]*\??/),
    Token.new(:integer, /\A[0-9]+/),
    Token.new(:string, /\A"(.*)"/) { _1[1] },
    Token.new(:symbol, /\A:([a-z]+[a-zA-Z_0-9]*\??)/) { _1[1] },

    Token.new(:comment, /\A#.*/),
    Token.new(:newline, /\A[\n]|\A[\r\n]/),
    Token.new(:left_round_bracket, /\A\(/),
    Token.new(:right_round_bracket, /\A\)/),
    Token.new(:left_square_bracket, /\A\[/),
    Token.new(:right_square_bracket, /\A\]/),
    Token.new(:arrow, /\A->/),
    Token.new(:space, /\A[ \t]/)
  ]

  SKIP_TOKENS = Set[:space, :comment]

  class Scanner
    attr_accessor :src

    def initialize(src)
      @src = src
    end

    def tokens
      result = []

      while src.length > 0
        match = sorted_matches.last
        raise SyntaxError.new("Unexpected input `#{src[0]}`") unless match
        result << match.to_a unless SKIP_TOKENS.include?(match.type)
        self.src = src[match.length..]
      end

      result
    end

    private
    def sorted_matches
      TOKEN_TYPES.filter_map do |type|
        type.match(src)
      end.sort_by(&:match_length_and_keyword_priority)
    end
  end
end
