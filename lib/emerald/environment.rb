class Emerald::Environment
  attr_reader :outer, :env, :constants

  attr_accessor :file, :current_offset

  def initialize(env = {}, outer: nil, file: nil, current_offset: 0)
    @constants      = {}
    @current_offset = current_offset
    @env            = env
    @file           = file
    @outer          = outer
  end

  def set(name, value)
    env[name] = value
  end

  def set_constant(name, value)
    constants[name] = value
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

  def get_constant(name)
    result = constants[name]
    result = outer.get_constant(name) if outer && result.nil?
    raise Emerald::NameError.new(
      "No constant with name #{name} found",
      file,
      current_offset
    ) if result.nil?
    result
  end

  def get_at_distance(distance, name)
    parent_at_distance(distance).get(name)
  end

  private
    def parent_at_distance(distance)
      target_env = self
      distance.times do |i|
        target_env = target_env.outer
      end
      target_env
    end
end
