require "pp"

module Emerald
  class Interpreter
    attr_reader :global_env, :had_error
    def initialize
      @global_env = Environment.new
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
      interprete_ast(ast, global_env).last
    rescue => e
      log_error e
    end

    private

    def define_builtins
      Emerald::Runtime.new.define_builtins(global_env)
    end

    def interprete_ast(ast, env)
      ast.map do |node|
        interprete_node(node, env)
      rescue => e
        log_error e
      end
    end

    def interprete_node(node, env)
      case node[0]
      when :integer
        node[1].to_i
      when :define
        (_, (_, ident), value_node) = node
        value = interprete_node(value_node, env)
        env.set(ident, value)
        ident
      when :identifier
        env.get(node[1])
      when :call
        fn = interprete_node(node[1], env)
        if node.length > 2
          args = interprete_ast(node[2..-1], env)
          fn[*args]
        else
          fn[]
        end
      when :array
        (_, *elements) = node
        Emerald::Types::Array.new(interprete_ast(elements, env))
      when :fn
        (_, params, body) = node
        arity = params.count
        Emerald::Types::Function.from_block("anonymous", arity) do |*args|
          block_env = Environment.new(
            params.zip(args).map { |((_, arg_name), arg_value)| [arg_name, arg_value] }.to_h,
            env
          )
          result = interprete_ast(body, block_env)
          result.last
        end
      end
    end

    def clear_error
      @had_error = false
    end

    def log_error(e)
      @had_error = true
      STDERR.puts "#{e.class}: #{e.message}"
      # STDERR.puts e.backtrace
    end
  end
end
