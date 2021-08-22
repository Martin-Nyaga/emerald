require "optparse"

module Emerald
  class Main
    class << self
      def run
        options = parse_options
        if options.count == 0 && ARGV.count == 0
          Emerald::Repl.run
        elsif options[:execute]
          Emerald::Interpreter.new.interprete(options[:execute])
        else
          code = File.read(ARGV[0])
          Emerald::Interpreter.new.interprete(code)
        end
      end

      def parse_options
        options = {}
        OptionParser.new do |opts|
          opts.banner = "Usage: emerald [options]"

          opts.on("-e \"<code>\"", "--execute \"<code>\"", "Execute one line of source code") do |code|
            options[:execute] = code.gsub("\\n", "\n")
          end

          opts.on("-h", "--help", "Show usage") do |code|
            puts opts
            exit
          end
        end.parse!

        options
      end
    end
  end
end
