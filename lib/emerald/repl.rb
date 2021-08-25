require "readline"

module Emerald
  class Repl
    def self.run
      interpreter = Interpreter.new(exit_on_error: false)
      while program = Readline.readline("iem> ", true)
        file = Emerald::Files::ScriptFile.new(program)
        result = interpreter.interprete(file)
        puts "=> #{result.to_s}" unless interpreter.had_error?
      end
    end
  end
end
