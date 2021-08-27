class Emerald::Environment
  attr_reader :outer, :env

  attr_accessor :file, :current_offset

  def initialize(env = {}, outer: nil, file: nil, current_offset: 0)
    @outer = outer
    @env = env
    @file = file
    @current_offset = current_offset
  end

  def set(name, value)
    env[name] = value
  end

  def get(name)
    result = env[name]
    result = outer.get(name) if outer && result.nil?
    raise Emerald::NameError.new(
      "No identifier with name #{name} found",
      file,
      current_offset
    ) if result.nil?
    result
  end
end
