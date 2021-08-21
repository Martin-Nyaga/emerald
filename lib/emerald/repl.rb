require "readline"

module Emerald
  class Repl
    def self.run
      interpreter = Interpreter.new
      while program = Readline.readline("iem> ", true)
        result = interpreter.interprete(program)
        puts "=> #{result.inspect}" unless interpreter.had_error?
      end
    end
  end
end
