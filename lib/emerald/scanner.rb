module Emerald
  class Scanner
    attr_reader :src

    def initialize(src)
      @src = src
    end

    def tokens
      result = []
      while src.length > 0
        matches = token_types
          .filter_map { |(type, matcher)| (match = matcher.match(src)) && [type, match] }
          .sort_by {|(type, match)| match.length }

        raise SyntaxError.new("Unexpected input `#{src[0]}`") if matches.length == 0

        (type, match) = matches.last
        result << [type, match[0]] unless type == :space
        @src = src.delete_prefix(match[0])
      end
      result
    end

    def token_types
      [
        [:integer, /^\d+/],
        [:identifier, /^[\+\-\/\*]|^[a-z]+[a-z_0-9]*/],
        [:space, /^\s/]
      ]
    end
  end
end
