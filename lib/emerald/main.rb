module Emerald
  class Main
    def self.run
      if ARGV.count > 0
        Emerald::Interpreter.run_file(ARGV[0])
      else
        Emerald::Repl.run
      end
    end
  end
end
