module Emerald
  class SyntaxError < StandardError; end

  autoload :Main, "emerald/main"

  autoload :Scanner, "emerald/scanner"
  autoload :Parser, "emerald/parser"
  autoload :Interpreter, "emerald/interpreter"
  autoload :Repl, "emerald/repl"

  autoload :Types, "emerald/types"
end
