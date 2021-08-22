require "spec_helper"
require "emerald/scanner"

describe Emerald::Scanner do
  it "can tokenise integers" do
    tokens = Emerald::Scanner.new("1").tokens
    expect(tokens).to eq([[:integer, "1"]])
  end

  context "identifiers" do
    it "allows alphanumeric identifiers tokenise identifiers" do
      tokens = Emerald::Scanner.new("foo").tokens
      result = [[:identifier, "foo"]]
      expect(tokens).to eq(result)

      tokens = Emerald::Scanner.new("foo123").tokens
      result = [[:identifier, "foo123"]]
      expect(tokens).to eq(result)
    end

    it "allows +-/* as independent identifiers" do
      "+-/*".split("").each do |op|
        tokens = Emerald::Scanner.new(op).tokens
        result = [[:identifier, op]]
        expect(tokens).to eq(result)
      end
    end
  end

  it "can tokenise a sequence of integers and identifiers" do
    tokens = Emerald::Scanner.new("foo 1 1").tokens
    result = [[:identifier, "foo"], [:integer, "1"], [:integer, "1"]]
    expect(tokens).to eq(result)
  end

  it "can tokenise a multiline statement" do
    tokens = Emerald::Scanner.new("foo 1 1\n+ 3 3").tokens
    result = [
      [:identifier, "foo"], [:integer, "1"], [:integer, "1"],
      [:newline, "\n"],
      [:identifier, "+"], [:integer, "3"], [:integer, "3"]
    ]
    expect(tokens).to eq(result)
  end

  it "can tokenise a parenthesized call" do
    tokens = Emerald::Scanner.new("foo (+ 1 1) 1").tokens
    result = [
      [:identifier, "foo"], [:left_round_bracket, "("], [:identifier, "+"],
      [:integer, "1"], [:integer, "1"], [:right_round_bracket, ")"], [:integer, "1"]
    ]
    expect(tokens).to eq(result)
  end

  it "can tokenise a definition" do
    tokens = Emerald::Scanner.new("def foo 12").tokens
    result = [[:def, "def"], [:identifier, "foo"], [:integer, "12"]]
    expect(tokens).to eq(result)
  end

  it "can tokenise array syntax" do
    tokens = Emerald::Scanner.new("print [1 2]").tokens
    result = [
      [:identifier, "print"], [:left_square_bracket, "["], [:integer, "1"],
      [:integer, "2"], [:right_square_bracket, "]"]
    ]
    expect(tokens).to eq(result)
  end

  context "functions" do
    it "can tokenise single line anonymous function syntax" do
      tokens = Emerald::Scanner.new("fn a => print a").tokens
      result = [[:fn, "fn"], [:identifier, "a"], [:fat_arrow, "=>"], [:identifier, "print"], [:identifier, "a"]]
      expect(tokens).to eq(result)
    end

    it "can tokenise single line named function syntax" do
      tokens = Emerald::Scanner.new("defn say a => print a").tokens
      result = [
        [:defn, "defn"], [:identifier, "say"], [:identifier, "a"],
        [:fat_arrow, "=>"], [:identifier, "print"], [:identifier, "a"]
      ]
      expect(tokens).to eq(result)
    end
  end
end
