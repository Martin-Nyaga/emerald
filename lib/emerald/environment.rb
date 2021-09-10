class Emerald::Environment
  attr_reader :outer, :env, :constants

  attr_accessor :file, :current_offset, :scoped_locals

  def initialize(env: {}, outer: nil, file: nil, current_offset: 0, scoped_locals: {})
    @constants = {}
    @current_offset = current_offset
    @scoped_locals = scoped_locals
    @env = env
    @file = file
    @outer = outer
    @stack_frames = []
  end

  def set(name, value)
    env[name] = value
  end

  def set_constant(name, value)
    constants[name] = value
  end

  def get(name, raise_if_not_exists: true)
    result = env[name]
    if outer && result.nil?
      result = outer.get(
        name, raise_if_not_exists: raise_if_not_exists
      )
    end
    if result.nil? && raise_if_not_exists
      raise Emerald::NameError.new(
        "No identifier with name #{name} found",
        file,
        current_offset
      )
    end
    result
  end

  def get_constant(name, raise_if_not_exists: true)
    result = constants[name]
    if outer && result.nil?
      result = outer.get_constant(
        name, raise_if_not_exists: raise_if_not_exists
      )
    end
    if result.nil? && raise_if_not_exists
      raise Emerald::NameError.new(
        "No constant with name #{name} found",
        file,
        current_offset
      )
    end
    result
  end

  def get_at_distance(distance, name, raise_if_not_exists: true)
    parent_at_distance(distance).get(
      name, raise_if_not_exists: raise_if_not_exists
    )
  end

  StackFrame = Struct.new(:file, :offset, :function) do
    def file_path
      file.path
    end

    def line_number
      file.line_number(offset)
    end

    def column_number
      file.line(offset).line_offset(offset)
    end

    def to_formatted_s
      "in #{file_path}:#{line_number} at `#{function.name}`"
    end
  end

  def new_stack_frame(function)
    StackFrame.new(file, current_offset, function)
  end

  def push_stack_frame(frame)
    if outer.nil?
      @stack_frames.push(frame)
    else
      outer.push_stack_frame(frame)
    end
  end

  def pop_stack_frame
    if outer.nil?
      @stack_frames.pop
    else
      outer.pop_stack_frame
    end
  end

  def stack_frames
    if outer.nil?
      @stack_frames
    else
      outer.stack_frames
    end
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
