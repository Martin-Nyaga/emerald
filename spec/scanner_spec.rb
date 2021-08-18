require "spec_helper"
require "emerald/scanner"

describe Emerald::Scanner do
  it "can tokenise integers" do
    tokens = Emerald::Scanner.new("1").tokens
    expect(tokens).to eq([[:integer, "1"]])
  end

  it "can tokenise identifiers" do
    tokens = Emerald::Scanner.new("foo").tokens
    result = [[:identifier, "foo"]]
    expect(tokens).to eq(result)
  end

  it "can tokenise a sequence of integers and identifiers" do
    tokens = Emerald::Scanner.new("foo 1 1").tokens
    result = [[:identifier, "foo"], [:integer, "1"], [:integer, "1"]]
    expect(tokens).to eq(result)
  end
end
