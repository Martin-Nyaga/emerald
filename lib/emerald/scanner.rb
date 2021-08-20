module Emerald
  class Token
    attr_reader :type, :pattern
    def initialize(type, pattern)
      @type, @pattern = type, pattern
    end

    def match(str)
      if match = pattern.match(str)
        return [type, match]
      else
        nil
      end
    end
  end

  TOKEN_TYPES = [
    Token.new(:integer, /\A[0-9]+/),
    Token.new(:identifier, /\A[\+\-\/\*]|\A[a-z]+[a-z_0-9]*/),
    Token.new(:space, /\A[ \t]/),
    Token.new(:newline, /\A[\n]|\A[\r\n]/)
  ]

class Scanner
  attr_accessor :src

  def initialize(src)
    @src = src
  end

    def tokens
      result = []
      while src.length > 0
        matches = TOKEN_TYPES.filter_map { |type| type.match(src) }
                             .sort_by    { |(type, match)| match.length }

        raise SyntaxError.new("Unexpected input `#{src[0]}`") if matches.length == 0

        (type, match) = matches.last
        result << [type, match[0]] unless type == :space
        self.src = src.delete_prefix(match[0])
      end
      result
    end

  end
end
