module Emerald
  autoload :Main, "emerald/main"

  autoload :Scanner, "emerald/scanner"
  autoload :Parser, "emerald/parser"
  autoload :Interpreter, "emerald/interpreter"
  autoload :Repl, "emerald/repl"
  autoload :Runtime, "emerald/runtime"
  autoload :Environment, "emerald/environment"

  autoload :Types, "emerald/types"
  autoload :Files, "emerald/files"

  require "emerald/error"
end
