require "emerald/runtime"
require "pp"

module Emerald
  class Interpreter
    attr_reader :env, :had_error
    def initialize
      @env = {}
      @had_error = false

      define_builtins
    end

    def had_error?
      had_error
    end

    def interprete(program)
      clear_error
      tokens = Emerald::Scanner.new(program).tokens
      pp tokens
      ast = Emerald::Parser.new(tokens).parse
      pp ast
      interprete_ast(ast).last
    rescue => e
      log_error e
    end

    private

    def define_builtins
      Emerald::Runtime.new.define_builtins(env)
    end

    def interprete_ast(ast)
      ast.map do |node|
        interprete_node(node)
      rescue => e
        log_error e
      end
    end

    def interprete_node(node)
      case node[0]
      when :integer
        node[1].to_i
      when :identifier
        result = env[node[1]]
        raise NameError.new("No identifier with name #{node[1]} found") if result.nil?
        result
      when :call
        fn = interprete_node(node[1])
        if node.length > 2
          args = interprete_ast(node[2..-1])
          fn[*args]
        else
          fn[]
        end
      end
    end

    def clear_error
      @had_error = false
    end

    def log_error(e)
      @had_error = true
      STDERR.puts "#{e.class}: #{e.message}"
    end
  end
end
