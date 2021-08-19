require "spec_helper"

describe Emerald::Interpreter do
  it "can interpret an integer" do
    result = Emerald::Interpreter.new.interprete("1")
    expect(result).to eq(1)
  end

  context "with basic math expressions" do
    it "works" do
      result = Emerald::Interpreter.new.interprete("+ 1 1")
      expect(result).to eq(2)
      result = Emerald::Interpreter.new.interprete("- 3 2")
      expect(result).to eq(1)
      result = Emerald::Interpreter.new.interprete("* 3 2")
      expect(result).to eq(6)
      result = Emerald::Interpreter.new.interprete("/ 4 2")
      expect(result).to eq(2)
    end
  end
end
