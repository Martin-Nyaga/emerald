require "optparse"

module Emerald
  class Main
    class << self
      def run
        options = parse_options
        if options.count == 0 && ARGV.count == 0
          Emerald::Repl.run
        elsif options[:execute]
          file = Emerald::Files::ScriptFile.new(options[:execute])
          run_file_with_options file, options
        else
          file = Emerald::Files::RealFile.new(ARGV[0])
          run_file_with_options file, options
        end
      end

      def run_file_with_options file, options
        if options[:ast]
          print_ast(file)
        else
          Emerald::Interpreter.new.interprete(file)
        end
      end

      def print_ast(file)
        tokens = Emerald::Scanner.new(file).tokens
        pp Emerald::Parser.new(file, tokens).parse
      rescue Emerald::Error => e
        puts e.to_s
      end

      def parse_options
        options = {}
        OptionParser.new do |opts|
          opts.banner = "Usage: emerald [options]"

          opts.on("-e \"<code>\"", "--execute \"<code>\"", "Execute one line of source code") do |code|
            options[:execute] = code.gsub("\\n", "\n")
          end

          opts.on("--ast", "Print ast") do |ast|
            options[:ast] = ast
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
