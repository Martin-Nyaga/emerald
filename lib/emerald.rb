module Emerald
  class SyntaxError < StandardError; end

  autoload :Scanner, "emerald/scanner"
  autoload :Parser, "emerald/parser"
end
