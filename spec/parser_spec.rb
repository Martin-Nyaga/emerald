require "spec_helper"

describe Emerald::Parser do
  context "terminal" do
    it "can parse an integer" do
      src = "1"
      ast = Emerald::Parser.new(Emerald::Scanner.new(src).tokens).parse
      result = [[:integer, "1"]]
      expect(ast).to eq(result)
    end
  end

  context "call" do
    it "can parse a call" do
      src = "foo 1 1"
      ast = Emerald::Parser.new(Emerald::Scanner.new(src).tokens).parse
      result = [[:call, [[:identifier, "foo"], [:integer, "1"], [:integer, "1"]]]]
      expect(ast).to eq(result)
    end
  end
end
