require "spec_helper"
require "emerald/error"

describe Emerald::Error do
  it "shows a contextual error message for a single line script" do
    file = Emerald::Files::ScriptFile.new("foo @ world")
    raise Emerald::Error.new("test error", file, 4)
  rescue Emerald::Error => e
    message = <<~MSG

      Error: test error
          in #{file.path} on line 1

          1| foo @ world
           |     ^
                 here
    MSG
    expect(e.to_s).to eq(message)
  end

  it "shows a contextual error message for a multiline file/script" do
    file = Emerald::Files::ScriptFile.new("foo bar\n@ world")
    raise Emerald::Error.new("test error", file, 8)
  rescue Emerald::Error => e
    message = <<~MSG

      Error: test error
          in #{file.path} on line 2

          1| foo bar
          2| @ world
           | ^
             here
    MSG
    expect(e.to_s).to eq(message)
  end
end
