class Emerald::Environment
  attr_reader :outer, :env
  def initialize(env = {}, outer = nil)
    @outer = outer
    @env = env
  end

  def set(name, value)
    env[name] = value
  end

  def get(name)
    result = env[name]
    result = outer.get(name) if outer && result.nil?
    raise NameError.new("No identifier with name #{name} found") if result.nil?
    result
  end
end
