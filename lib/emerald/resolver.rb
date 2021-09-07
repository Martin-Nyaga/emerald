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
      send("resolve_#{node.type}", node)
    rescue NoMethodError
      raise Emerald::NotImplementedError.new(
        "resolution for :#{node.type} not implemented",
        file,
        node.offset
      )
    end

    def resolve_collection_node(node)
      (_, *elements) = node
      elements.map do |node|
        resolve_node(node)
      end
    end
    alias_method :resolve_array, :resolve_collection_node
    alias_method :resolve_hashmap, :resolve_collection_node

    def resolve_block(node)
      node.children.each do |node|
        resolve_node(node)
      end
    end

    def resolve_call(node)
      (_, fn, *args) = node
      resolve_node(fn)
      args.each do |arg|
        resolve_node(arg)
      end
    end

    def resolve_def(node)
      (_, (_, name), value) = node
      declare(name)
      resolve_node(value)
      define(name)
    end

    def resolve_defn(node)
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
    end

    def resolve_fn(node)
      (_, params, body) = node
      push_scope
      params.children.each do |_, param_name|
        declare(param_name)
        define(param_name)
      end
      resolve_node(body)
      pop_scope
    end

    def resolve_guards(node)
      (_, *guards) = node
      guards.each do |(_, condition, body)|
        resolve_node(condition)
        resolve_node(body)
      end
    end

    def resolve_conditional(node)
      (_, condition, body, else_body) = node
      resolve_node(condition)
      resolve_node(body)
      resolve_node(else_body) if else_body.any?
    end
    alias_method :resolve_if, :resolve_conditional
    alias_method :resolve_unless, :resolve_conditional

    def resolve_noop(node)
      # Noop
    end
    alias_method :resolve_integer, :resolve_noop
    alias_method :resolve_string, :resolve_noop
    alias_method :resolve_symbol, :resolve_noop
    alias_method :resolve_true, :resolve_noop
    alias_method :resolve_false, :resolve_noop
    alias_method :resolve_nil, :resolve_noop
    alias_method :resolve_constant, :resolve_noop
    alias_method :resolve_deftype, :resolve_noop
    alias_method :resolve_ref, :resolve_noop
    alias_method :resolve_constructor, :resolve_noop
    alias_method :resolve_import, :resolve_noop

    def resolve_identifier(node)
      (_, name) = node
      if scopes.any? && scopes.last[name] == false
        raise Emerald::SyntaxError.new(
          "Can't refer to a variable in it's own definition",
          file,
          node.offset
        )
      end
      resolve_local(node, name)
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
