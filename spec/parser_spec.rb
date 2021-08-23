require "spec_helper"

describe Emerald::Parser do
  context "terminal" do
    it "can parse an integer" do
      src = "1"
      ast = Emerald::Parser.new(Emerald::Scanner.new(src).tokens).parse
      result = [[:integer, "1"]]
      expect(ast).to eq(result)
    end

    it "can parse a string" do
      src = %( "hello world" )
      ast = Emerald::Parser.new(Emerald::Scanner.new(src).tokens).parse
      result = [[:string, "hello world"]]
      expect(ast).to eq(result)
    end
  end

  context "call" do
    it "can parse a call" do
      src = "foo 1 1"
      ast = Emerald::Parser.new(Emerald::Scanner.new(src).tokens).parse
      result = [[:call, [:identifier, "foo"], [:integer, "1"], [:integer, "1"]]]
      expect(ast).to eq(result)
    end

    it "can parse a call with identifiers" do
      src = "foo bar baz"
      ast = Emerald::Parser.new(Emerald::Scanner.new(src).tokens).parse
      result = [[:call, [:identifier, "foo"], [:identifier, "bar"], [:identifier, "baz"]]]
      expect(ast).to eq(result)
    end
  end

  context "multiline" do
    it "can parse a multiline program" do
      src = "foo 1 1\nbar 1 1"
      ast = Emerald::Parser.new(Emerald::Scanner.new(src).tokens).parse
      result = [
        [:call, [:identifier, "foo"], [:integer, "1"], [:integer, "1"]],
        [:call, [:identifier, "bar"], [:integer, "1"], [:integer, "1"]]
      ]
      expect(ast).to eq(result)
    end
  end

  context "parenthesized" do
    it "can parse a parenthesized call" do
      src = "foo (+ 1 1) 1"
      ast = Emerald::Parser.new(Emerald::Scanner.new(src).tokens).parse
      result = [
        [:call, [:identifier, "foo"],
          [:call, [:identifier, "+"], [:integer, "1"], [:integer, "1"]],
          [:integer, "1"]]
      ]
      expect(ast).to eq(result)
    end
  end

  context "def" do
    it "can parse a definition call" do
      src = "def foo 12"
      ast = Emerald::Parser.new(Emerald::Scanner.new(src).tokens).parse
      result = [[:def, [:identifier, "foo"], [:integer, "12"]]]
      expect(ast).to eq(result)
    end
  end

  context "array" do
    it "can parse array syntax" do
      src = "print [1 2]"
      ast = Emerald::Parser.new(Emerald::Scanner.new(src).tokens).parse
      result = [[:call, [:identifier, "print"], [:array, [:integer, "1"], [:integer, "2"]]]]
      expect(ast).to eq(result)
    end
  end

  context "functions" do
    it "can parse a single line anonymous function definition" do
      src = "fn a -> print a"
      ast = Emerald::Parser.new(Emerald::Scanner.new(src).tokens).parse
      result = [[:fn, [[:identifier, "a"]], [[:call, [:identifier, "print"], [:identifier, "a"]]]]]
      expect(ast).to eq(result)
    end

    it "can parse a single line named function definition" do
      src = "defn say a -> print a"
      ast = Emerald::Parser.new(Emerald::Scanner.new(src).tokens).parse
      result = [[:defn, [:identifier, "say"], [[:identifier, "a"]], [[:call,
        [:identifier, "print"], [:identifier, "a"]]]]]
      expect(ast).to eq(result)
    end

    it "can parse a multi-line anonymous function definition" do
      src = "fn a b do\n print a\nprint b\n end"
      ast = Emerald::Parser.new(Emerald::Scanner.new(src).tokens).parse
      result = [
        [:fn,
          [[:identifier, "a"], [:identifier, "b"]],
          [
            [:call, [:identifier, "print"], [:identifier, "a"]],
            [:call, [:identifier, "print"], [:identifier, "b"]]]]]
      expect(ast).to eq(result)
    end

    it "can parse a multi-line named function definition" do
      src = "defn say a b do\n print a \n print b\n end"
      ast = Emerald::Parser.new(Emerald::Scanner.new(src).tokens).parse
      result = [
        [:defn,
          [:identifier, "say"],
          [[:identifier, "a"], [:identifier, "b"]],
          [
            [:call, [:identifier, "print"], [:identifier, "a"]],
            [:call, [:identifier, "print"], [:identifier, "b"]]]]]
      expect(ast).to eq(result)
    end
  end

  context "true/false/nil" do
    it "can parse true" do
      src = "true"
      ast = Emerald::Parser.new(Emerald::Scanner.new(src).tokens).parse
      result = [[:true]]
      expect(ast).to eq(result)
    end

    it "can parse false" do
      src = "false"
      ast = Emerald::Parser.new(Emerald::Scanner.new(src).tokens).parse
      result = [[:false]]
      expect(ast).to eq(result)
    end

    it "can parse nil" do
      src = "nil"
      ast = Emerald::Parser.new(Emerald::Scanner.new(src).tokens).parse
      result = [[:nil]]
      expect(ast).to eq(result)
    end
  end

  context "if/unless statement" do
    it "can parse a multiline if statement" do
      src = "if true do\n print a \nend"
      ast = Emerald::Parser.new(Emerald::Scanner.new(src).tokens).parse
      result = [
        [:if, [:true],
          [[:call, [:identifier, "print"], [:identifier, "a"]]],
          []]]
      expect(ast).to eq(result)
    end

    it "can parse a multiline if else" do
      src = "if true do\n print a \nelse \nprint b \n end"
      ast = Emerald::Parser.new(Emerald::Scanner.new(src).tokens).parse
      result = [
        [:if, [:true],
          [[:call, [:identifier, "print"], [:identifier, "a"]]],
          [[:call, [:identifier, "print"], [:identifier, "b"]]]]]
      expect(ast).to eq(result)
    end

    it "can parse a single line if statement" do
      src = "if true -> print a"
      ast = Emerald::Parser.new(Emerald::Scanner.new(src).tokens).parse
      result = [
        [:if, [:true],
          [[:call, [:identifier, "print"], [:identifier, "a"]]],
          []]]
      expect(ast).to eq(result)
    end

    it "can parse a multiline unless statement" do
      src = "unless true do\n print a \nend"
      ast = Emerald::Parser.new(Emerald::Scanner.new(src).tokens).parse
      result = [
        [:unless, [:true],
          [[:call, [:identifier, "print"], [:identifier, "a"]]],
          []]]
      expect(ast).to eq(result)
    end

    it "can parse a multiline unless else" do
      src = "unless true do\n print a \nelse \nprint b \n end"
      ast = Emerald::Parser.new(Emerald::Scanner.new(src).tokens).parse
      result = [
        [:unless, [:true],
          [[:call, [:identifier, "print"], [:identifier, "a"]]],
          [[:call, [:identifier, "print"], [:identifier, "b"]]]]]
      expect(ast).to eq(result)
    end

    it "can parse a single line unless statement" do
      src = "unless true -> print a"
      ast = Emerald::Parser.new(Emerald::Scanner.new(src).tokens).parse
      result = [
        [:unless, [:true],
          [[:call, [:identifier, "print"], [:identifier, "a"]]],
          []]]
      expect(ast).to eq(result)
    end
  end
end
