class Emerald::Environment
  attr_reader :outer, :env

  def initialize(env = {}, outer = nil)
    @outer = outer
    @env = env
  end

  def set(name, value)
    env[name] = value
  end

  def get(name, file, node)
    result = env[name]
    result = outer.get(name, file, node) if outer && result.nil?
    raise Emerald::NameError.new(
      "No identifier with name #{name} found",
      file,
      node.offset
    ) if result.nil?
    result
  end
end
