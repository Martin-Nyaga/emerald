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
      ast = Emerald::Parser.new(tokens).parse
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
      when :define
        (_, (_, ident), value_node) = node
        value = interprete_node(value_node)
        env[ident] = value
      when :identifier
        (_, name) = node
        result = env[name]
        raise NameError.new("No identifier with name #{name} found") if result.nil?
        result
      when :call
        fn = interprete_node(node[1])
        if node.length > 2
          args = interprete_ast(node[2..-1])
          fn[*args]
        else
          fn[]
        end
      when :array
        (_, *elements) = node
        Emerald::Types::Array.new(interprete_ast(elements))
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
