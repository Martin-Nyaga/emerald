module Emerald
  class Resolver
    attr_reader :file, :ast, :locals
    def initialize(file, ast)
      @file = file
      @ast = ast
      @scopes = []
      @locals = {}
    end

    def resolve_locals
      resolve_node(ast)
      [ast, locals]
    end

    private

    attr_reader :scopes

    def resolve_node(node)
      case node.type
      when :array, :hashmap
        (_, *elements) = node
        elements.map do |node|
          resolve_node(node)
        end
      when :block
        node.children.each do |node|
          resolve_node(node)
        end
      when :call
        (_, fn, *args) = node
        resolve_node(fn)
        args.each do |arg|
          resolve_node(arg)
        end
      when :def
        (_, (_, name), value) = node
        declare(name)
        resolve_node(value)
        define(name)
      when :defn
        (_, (_, name), params, body) = node
        declare(name)
        define(name)
        push_scope
        params.children.each do |_, param_name|
          declare(param_name)
          define(param_name)
        end
        resolve_node(body)
        pop_scope
      when :fn
        (_, params, body) = node
        push_scope
        params.children.each do |_, param_name|
          declare(param_name)
          define(param_name)
        end
        resolve_node(body)
        pop_scope
      when :guards
        (_, *guards) = node
        guards.each do |(_, condition, body)|
          resolve_node(condition)
          resolve_node(body)
        end
      when :if, :unless
        (_, condition, body, else_body) = node
        resolve_node(condition)
        resolve_node(body)
        resolve_node(else_body) if else_body.any?
      when :integer, :string, :symbol, :true, :false, :nil, :constant, :deftype, :ref, :constructor
        # noop
      when :identifier
        (_, name) = node
        if scopes.any? && scopes.last[name] == false
          raise Emerald::SyntaxError.new(
            "Can't refer to a variable in it's own definition",
            file,
            node.offset
          )
        end
        resolve_local(node, name)
      else
        raise Emerald::NotImplementedError.new(
          "resolution for :#{node.type} not implemented",
          file,
          node.offset
        )
      end
    end

    def push_scope
      scopes.push({})
    end

    def pop_scope
      scopes.pop
    end

    def declare(name)
      return if scopes.empty?
      scopes.last[name] = false
    end

    def define(name)
      return if scopes.empty?
      scopes.last[name] = true
    end

    def resolve_local(node, name)
      scopes.each_with_index.to_a.reverse_each do |scope, index|
        if scope.key?(name)
          locals[node] = scopes.size - index - 1
        end
      end
    end
  end
end
