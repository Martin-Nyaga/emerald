module Emerald
  class Main
    def self.run
      if ARGV.count > 0
        code = File.read(ARGV[0])
        Emerald::Interpreter.new.interprete(code)
      else
        Emerald::Repl.run
      end
    end
  end
end
