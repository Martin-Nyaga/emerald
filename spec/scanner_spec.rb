require "spec_helper"
require "emerald/scanner"

describe Emerald::Scanner do
  def tokenise(str)
    file = Emerald::Files::ScriptFile.new(str)
    [file, Emerald::Scanner.new(file).tokens]
  end

  it "can tokenise integers" do
    file,  tokens = tokenise "1"
    expect(tokens).to eq([ s(:integer, "1", offset: 0) ])
  end

  context "identifiers" do
    it "allows alphanumeric identifiers tokenise identifiers" do
      file, tokens = tokenise "foo"
      result = [ s(:identifier, "foo", offset: 0) ]
      expect(tokens).to eq(result)

      file, tokens = tokenise "foo123"
      result = [ s(:identifier, "foo123", offset: 0) ]
      expect(tokens).to eq(result)
    end

    it "allows +-/* as independent identifiers" do
      "+-/*".split("").each do |op|
        file, tokens = tokenise op
        result = [ s(:identifier, op, offset: 0) ]
        expect(tokens).to eq(result)
      end
    end
  end

  it "can tokenise a sequence of integers and identifiers" do
    file, tokens = tokenise "foo 1 1"
    result = [
      s(:identifier, "foo", offset: 0),
      s(:integer, "1", offset: 4),
      s(:integer, "1", offset: 6)
    ]
    expect(tokens).to eq(result)
  end

  it "can tokenise a multiline statement" do
    file, tokens = tokenise "foo 1 1\n+ 3 3"
    result = [
      s(:identifier, "foo", offset: 0),
      s(:integer, "1", offset: 4),
      s(:integer, "1", offset: 6),
      s(:newline, "\n", offset: 7),
      s(:identifier, "+", offset: 8),
      s(:integer, "3", offset: 10),
      s(:integer, "3", offset: 12)
    ]
    expect(tokens).to eq(result)
  end

  it "can tokenise a parenthesized call" do
    file, tokens = tokenise "foo (+ 1 1) 1"
    result = [
      s(:identifier, "foo", offset: 0),
      s(:left_round_bracket, "(", offset: 4),
      s(:identifier, "+", offset: 5),
      s(:integer, "1", offset: 7),
      s(:integer, "1", offset: 9),
      s(:right_round_bracket, ")", offset: 10),
      s(:integer, "1", offset: 12)
    ]
    expect(tokens).to eq(result)
  end

  it "can tokenise a definition" do
    file, tokens = tokenise "def foo 12"
    result = [
      s(:def, "def", offset: 0),
      s(:identifier, "foo", offset: 4),
      s(:integer, "12", offset: 8)
    ]
    expect(tokens).to eq(result)
  end

  it "can tokenise array syntax" do
    file, tokens = tokenise "print [1 2]"
    result = [
      s(:identifier, "print", offset: 0),
      s(:left_square_bracket, "[", offset: 6),
      s(:integer, "1", offset: 7),
      s(:integer, "2", offset: 9),
      s(:right_square_bracket, "]", offset: 10)
    ]
    expect(tokens).to eq(result)
  end

  context "functions" do
    it "can tokenise single line anonymous function syntax" do
      file, tokens = tokenise "fn a -> print a"
      result = [
        s(:fn, "fn", offset: 0),
        s(:identifier, "a", offset: 3),
        s(:arrow, "->", offset: 5),
        s(:identifier, "print", offset: 8),
        s(:identifier, "a", offset: 14)
      ]
      expect(tokens).to eq(result)
    end

    it "can tokenise single line named function syntax" do
      file, tokens = tokenise "defn say a -> print a"
      result = [
        s(:defn, "defn", offset: 0),
        s(:identifier, "say", offset: 5),
        s(:identifier, "a", offset: 9),
        s(:arrow, "->", offset: 11),
        s(:identifier, "print", offset: 14),
        s(:identifier, "a", offset: 20)
      ]
      expect(tokens).to eq(result)
    end

    it "can tokenise multi-line anonymous function syntax" do
      file, tokens = tokenise "fn a do\n print a\n end"
      result = [
        s(:fn, "fn", offset: 0),
        s(:identifier, "a", offset: 3),
        s(:do, "do", offset: 5),
        s(:newline, "\n", offset: 7),
        s(:identifier, "print", offset: 9),
        s(:identifier, "a", offset: 15),
        s(:newline, "\n", offset: 16),
        s(:end, "end", offset: 18)
      ]
      expect(tokens).to eq(result)
    end

    it "can tokenise multi-line named function syntax" do
      file, tokens = tokenise "defn say a do \nprint a \n end"
      result = [
        s(:defn, "defn", offset: 0),
        s(:identifier, "say", offset: 5),
        s(:identifier, "a", offset: 9),
        s(:do, "do", offset: 11),
        s(:newline, "\n", offset: 14),
        s(:identifier, "print", offset: 15),
        s(:identifier, "a", offset: 21),
        s(:newline, "\n", offset: 23),
        s(:end, "end", offset: 25)
      ]
      expect(tokens).to eq(result)
    end

    it "can tokenise function guards" do
      file, tokens = tokenise "fn a when > 0 a -> print a\nwhen < 0 a -> raise \"foo\""
      result = [
        s(:fn, "fn", offset: 0),
        s(:identifier, "a", offset: 3),
        s(:when, "when", offset: 5),
        s(:identifier, ">", offset: 10),
        s(:integer, "0", offset: 12),
        s(:identifier, "a", offset: 14),
        s(:arrow, "->", offset: 16),
        s(:identifier, "print", offset: 19),
        s(:identifier, "a", offset: 25),
        s(:newline, "\n", offset: 26),
        s(:when, "when", offset: 27),
        s(:identifier, "<", offset: 32),
        s(:integer, "0", offset: 34),
        s(:identifier, "a", offset: 36),
        s(:arrow, "->", offset: 38),
        s(:identifier, "raise", offset: 41),
        s(:string, "foo", offset: 47),
      ]
      expect(tokens).to eq(result)
    end
  end

  context "true/false/nil" do
    it "can tokenise true" do
      file, tokens = tokenise "true"
      result = [ s(:true, "true", offset: 0) ]
      expect(tokens).to eq(result)
    end
    it "can tokenise false" do
      file, tokens = tokenise "false"
      result = [ s(:false, "false", offset: 0) ]
      expect(tokens).to eq(result)
    end
    it "can tokenise nil" do
      file, tokens = tokenise "nil"
      result = [ s(:nil, "nil", offset: 0) ]
      expect(tokens).to eq(result)
    end
  end

  context "if/unless statements" do
    it "can tokenise an multiline if statement" do
      file, tokens = tokenise "if true do \nprint a \n end"
      result = [ s(:if, "if", offset: 0),
        s(:true, "true", offset: 3),
        s(:do, "do", offset: 8),
        s(:newline, "\n", offset: 11),
        s(:identifier, "print", offset: 12),
        s(:identifier, "a", offset: 18),
        s(:newline, "\n", offset: 20),
        s(:end, "end", offset: 22)
      ]
      expect(tokens).to eq(result)
    end

    it "can tokenise else" do
      file, tokens = tokenise "if true do \nprint a \n else\n print b\n end"
      result = [
        s(:if, "if", offset: 0),
        s(:true, "true", offset: 3),
        s(:do, "do", offset: 8),
        s(:newline, "\n", offset: 11),
        s(:identifier, "print", offset: 12),
        s(:identifier, "a", offset: 18),
        s(:newline, "\n", offset: 20),
        s(:else, "else", offset: 22),
        s(:newline, "\n", offset: 26),
        s(:identifier, "print", offset: 28),
        s(:identifier, "b", offset: 34),
        s(:newline, "\n", offset: 35),
        s(:end, "end", offset: 37)
      ]
      expect(tokens).to eq(result)
    end

    it "can tokenise a single line if statement" do
      file, tokens = tokenise "if true -> print a\n"
      result = [
        s(:if, "if", offset: 0),
        s(:true, "true", offset: 3),
        s(:arrow, "->", offset: 8),
        s(:identifier, "print", offset: 11),
        s(:identifier, "a", offset: 17),
        s(:newline, "\n", offset: 18)
      ]
      expect(tokens).to eq(result)
    end

    it "can tokenise an multiline unless statement" do
      file, tokens = tokenise "unless true do \nprint a \n end"
      result = [
        s(:unless, "unless", offset: 0),
        s(:true, "true", offset: 7),
        s(:do, "do", offset: 12),
        s(:newline, "\n", offset: 15),
        s(:identifier, "print", offset: 16),
        s(:identifier, "a", offset: 22),
        s(:newline, "\n", offset: 24),
        s(:end, "end", offset: 26)
      ]
      expect(tokens).to eq(result)
    end

    it "can tokenise else" do
      file, tokens = tokenise "unless true do \nprint a \n else\n print b\n end"
      result = [
        s(:unless, "unless", offset: 0),
        s(:true, "true", offset: 7),
        s(:do, "do", offset: 12),
        s(:newline, "\n", offset: 15),
        s(:identifier, "print", offset: 16),
        s(:identifier, "a", offset: 22),
        s(:newline, "\n", offset: 24),
        s(:else, "else", offset: 26),
        s(:newline, "\n", offset: 30),
        s(:identifier, "print", offset: 32),
        s(:identifier, "b", offset: 38),
        s(:newline, "\n", offset: 39),
        s(:end, "end", offset: 41)
      ]
      expect(tokens).to eq(result)
    end

    it "can tokenise a single line unless statement" do
      file, tokens = tokenise "unless true -> print a\n"
      result = [ s(:unless, "unless", offset: 0),
        s(:true, "true", offset: 7),
        s(:arrow, "->", offset: 12),
        s(:identifier, "print", offset: 15),
        s(:identifier, "a", offset: 21),
        s(:newline, "\n", offset: 22)
      ]
      expect(tokens).to eq(result)
    end
  end

  context "strings" do
    it "can tokenise a string" do
      file, tokens = tokenise %( "hello world" )
      result = [ s(:string, "hello world", offset: 1) ]
      expect(tokens).to eq(result)
    end

    it "can tokenise a multiple subsequent strings" do
      file, tokens = tokenise %( "hello" "world" )
      result = [
        s(:string, "hello", offset: 1),
        s(:string, "world", offset: 9)
      ]
      expect(tokens).to eq(result)
    end
  end

  context "symbols" do
    it "can tokenise a symbol" do
      file, tokens = tokenise ":foo"
      result = [ s(:symbol, "foo", offset: 0) ]
      expect(tokens).to eq(result)
    end
  end

  context "comments" do
    it "can skip over comments in the scanner" do
      file, tokens = tokenise "# this is a comment"
      result = []
      expect(tokens).to eq(result)
    end
  end

  context "invalid tokens" do
    it "returns a clear syntax error when an invalid token is detected" do
      expect { tokenise "def @ foo" }.to raise_error(Emerald::SyntaxError)
    end
  end
end
