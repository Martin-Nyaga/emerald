module Emerald
  class Token
    attr_reader :type, :pattern, :keyword
    def initialize(type, pattern, keyword = false)
      @type, @pattern, @keyword = type, pattern, keyword
    end

    def match(str)
      if match = pattern.match(str)
        return Match.new(type, match, keyword)
      else
        nil
      end
    end
  end

  class Match
    attr_reader :type, :matchdata, :keyword
    def initialize(type, matchdata, keyword)
      @type, @matchdata, @keyword = type, matchdata, keyword
    end

    def to_a
      [type, text]
    end

    def length
      text.length
    end

    def text
      matchdata[0]
    end

    def match_length_and_keyword_priority
      [length, keyword ? 1 : 0 ]
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

    Token.new(:identifier, /\A[\+\-\/\*]|\A[a-z]+[a-zA-Z_0-9]*/),
    Token.new(:integer, /\A[0-9]+/),
    Token.new(:newline, /\A[\n]|\A[\r\n]/),
    Token.new(:left_round_bracket, /\A\(/),
    Token.new(:right_round_bracket, /\A\)/),
    Token.new(:left_square_bracket, /\A\[/),
    Token.new(:right_square_bracket, /\A\]/),
    Token.new(:fat_arrow, /\A=>/),
    Token.new(:space, /\A[ \t]/),
  ]

class Scanner
  attr_accessor :src

  def initialize(src)
    @src = src
  end

    def tokens
      result = []
      while src.length > 0
        match =
          TOKEN_TYPES.filter_map { |type| type.match(src) }
            .sort_by(&:match_length_and_keyword_priority)
            .last

        raise SyntaxError.new("Unexpected input `#{src[0]}`") unless match

        result << match.to_a unless match.type == :space
        self.src = src.delete_prefix(match.text)
      end
      result
    end

  end
end
