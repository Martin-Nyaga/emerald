module Emerald
  autoload :Main, "emerald/main"

  autoload :Scanner, "emerald/scanner"
  autoload :Parser, "emerald/parser"
  autoload :Interpreter, "emerald/interpreter"
  autoload :Resolver, "emerald/resolver"
  autoload :Repl, "emerald/repl"
  autoload :Runtime, "emerald/runtime"
  autoload :Environment, "emerald/environment"

  autoload :Types, "emerald/types"
  autoload :Files, "emerald/files"

  require "emerald/error"
  require "emerald/sexp"
end
