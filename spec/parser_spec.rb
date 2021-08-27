require "spec_helper"

describe Emerald::Parser do
  def parse str
    file = Emerald::Files::ScriptFile.new(str)
    tokens = Emerald::Scanner.new(file).tokens
    Emerald::Parser.new(file, tokens).parse
  end

  context "empty" do
    it "can parse an empty list of tokens" do
      expect(parse "").to eq([])
    end
  end

  context "terminal" do
    it "can parse an integer" do
      src = "1"
      result = [[:integer, "1", 0]]
      expect(parse src).to eq(result)
    end

    it "can parse a string" do
      src = %( "hello world" )
      result = [[:string, "hello world", 1]]
      expect(parse src).to eq(result)
    end

    it "can parse a symbol" do
      src = ":foo"
      result = [[:symbol, "foo", 0]]
      expect(parse src).to eq(result)
    end
  end

  context "call" do
    it "can parse a call" do
      src = "foo 1 1"
      result = [[:call, [:identifier, "foo", 0], [:integer, "1", 4], [:integer, "1", 6]]]
      expect(parse src).to eq(result)
    end

    it "can parse a call with identifiers" do
      src = "foo bar baz"
      result = [[:call, [:identifier, "foo", 0], [:identifier, "bar", 4], [:identifier, "baz", 8]]]
      expect(parse src).to eq(result)
    end
  end

  context "multiline" do
    it "can parse a multiline program" do
      src = "foo 1 1\nbar 1 1"
      result = [
        [:call, [:identifier, "foo", 0], [:integer, "1", 4], [:integer, "1", 6]],
        [:call, [:identifier, "bar", 8], [:integer, "1", 12], [:integer, "1", 14]]
      ]
      expect(parse src).to eq(result)
    end
  end

  context "parenthesized" do
    it "can parse a parenthesized call" do
      src = "foo (+ 1 1) 1"
      result = [
        [:call, [:identifier, "foo", 0],
          [:call, [:identifier, "+", 5], [:integer, "1", 7], [:integer, "1", 9]],
          [:integer, "1", 12]]
      ]
      expect(parse src).to eq(result)
    end

    it "raises a syntax error for unclosed parens" do
      src = "foo ("
      expect { parse src }.to raise_error(Emerald::SyntaxError)
    end
  end

  context "def" do
    it "can parse a definition call" do
      src = "def foo 12"
      result = [[:def, [:identifier, "foo", 4], [:integer, "12", 8]]]
      expect(parse src).to eq(result)
    end
  end

  context "array" do
    it "can parse array syntax" do
      src = "print [1 2]"
      result = [[:call, [:identifier, "print", 0], [:array, [:integer, "1", 7], [:integer, "2", 9]]]]
      expect(parse src).to eq(result)
    end

    it "raises a syntax error for unclosed square brackets" do
      src = "foo ["
      expect { parse src }.to raise_error(Emerald::SyntaxError)
    end
  end

  context "functions" do
    it "can parse a single line anonymous function definition" do
      src = "fn a -> print a"
      result = [[:fn, [[:identifier, "a", 3]], [[:call, [:identifier, "print", 8], [:identifier, "a", 14]]]]]
      expect(parse src).to eq(result)
    end

    it "can parse a single line named function definition" do
      src = "defn say a -> print a"
      result = [[:defn, [:identifier, "say", 5], [[:identifier, "a", 9]], [[:call,
        [:identifier, "print", 14], [:identifier, "a", 20]]]]]
      expect(parse src).to eq(result)
    end

    it "can parse a multi-line anonymous function definition" do
      src = "fn a b do\n print a\nprint b\n end"
      result = [
        [:fn,
          [[:identifier, "a", 3], [:identifier, "b", 5]],
          [
            [:call, [:identifier, "print", 11], [:identifier, "a", 17]],
            [:call, [:identifier, "print", 19], [:identifier, "b", 25]]]]]
      expect(parse src).to eq(result)
    end

    it "can parse a multi-line named function definition" do
      src = "defn say a b do\n print a \n print b\n end"
      result = [
        [:defn,
          [:identifier, "say", 5],
          [[:identifier, "a", 9], [:identifier, "b",  11]],
          [
            [:call, [:identifier, "print", 17], [:identifier, "a", 23]],
            [:call, [:identifier, "print", 27], [:identifier, "b", 33]]]]]
      expect(parse src).to eq(result)
    end

    it "raises a syntax error for do without end" do
      src = "defn bar do"
      expect { parse src }.to raise_error(Emerald::SyntaxError)

      src = "fn bar do"
      expect { parse src }.to raise_error(Emerald::SyntaxError)
    end

    it "raises a syntax error for single line function without a body" do
      src = "fn a ->"
      expect { parse src }.to raise_error(Emerald::SyntaxError)
    end
  end

  context "true/false/nil" do
    it "can parse true" do
      src = "true"
      result = [[:true]]
      expect(parse src).to eq(result)
    end

    it "can parse false" do
      src = "false"
      result = [[:false]]
      expect(parse src).to eq(result)
    end

    it "can parse nil" do
      src = "nil"
      result = [[:nil]]
      expect(parse src).to eq(result)
    end
  end

  context "if/unless statement" do
    it "can parse a multiline if statement" do
      src = "if true do\n print a \nend"
      result = [
        [:if, [:true],
          [[:call, [:identifier, "print", 12], [:identifier, "a", 18]]],
          []]]
      expect(parse src).to eq(result)
    end

    it "can parse a multiline if else" do
      src = "if true do\n print a \nelse \nprint b \n end"
      result = [
        [:if, [:true],
          [[:call, [:identifier, "print", 12], [:identifier, "a", 18]]],
          [[:call, [:identifier, "print", 27], [:identifier, "b", 33]]]]]
      expect(parse src).to eq(result)
    end

    it "can parse a single line if statement" do
      src = "if true -> print a"
      result = [
        [:if, [:true],
          [[:call, [:identifier, "print", 11], [:identifier, "a", 17]]],
          []]]
      expect(parse src).to eq(result)
    end

    it "can parse a multiline unless statement" do
      src = "unless true do\n print a \nend"
      result = [
        [:unless, [:true],
          [[:call, [:identifier, "print", 16], [:identifier, "a", 22]]],
          []]]
      expect(parse src).to eq(result)
    end

    it "can parse a multiline unless else" do
      src = "unless true do\n print a \nelse \nprint b \n end"
      result = [
        [:unless, [:true],
          [[:call, [:identifier, "print", 16], [:identifier, "a", 22]]],
          [[:call, [:identifier, "print", 31], [:identifier, "b", 37]]]]]
      expect(parse src).to eq(result)
    end

    it "can parse a single line unless statement" do
      src = "unless true -> print a"
      result = [
        [:unless, [:true],
          [[:call, [:identifier, "print", 15], [:identifier, "a", 21]]],
          []]]
      expect(parse src).to eq(result)
    end

    it "raises a syntax error for do without end" do
      src = "if bar do"
      expect { parse src }.to raise_error(Emerald::SyntaxError)

      src = "if bar do baz else"
      expect { parse src }.to raise_error(Emerald::SyntaxError)

      src = "unless bar do baz else"
      expect { parse src }.to raise_error(Emerald::SyntaxError)

    end

    it "raises a syntax error for single line function if/unless a body" do
      src = "if a ->"
      expect { parse src }.to raise_error(Emerald::SyntaxError)

      src = "unless a ->"
      expect { parse src }.to raise_error(Emerald::SyntaxError)
    end
  end
end
