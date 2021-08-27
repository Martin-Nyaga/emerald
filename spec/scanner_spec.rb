require "spec_helper"
require "emerald/scanner"

describe Emerald::Scanner do
  def tokenise(str)
    file = Emerald::Files::ScriptFile.new(str)
    [file, Emerald::Scanner.new(file).tokens]
  end

  it "can tokenise integers" do
    file,  tokens = tokenise "1"
    expect(tokens).to eq([[:integer, "1", 0]])
  end

  context "identifiers" do
    it "allows alphanumeric identifiers tokenise identifiers" do
      file, tokens = tokenise "foo"
      result = [[:identifier, "foo", 0]]
      expect(tokens).to eq(result)

      file, tokens = tokenise "foo123"
      result = [[:identifier, "foo123", 0]]
      expect(tokens).to eq(result)
    end

    it "allows +-/* as independent identifiers" do
      "+-/*".split("").each do |op|
        file, tokens = tokenise op
        result = [[:identifier, op, 0]]
        expect(tokens).to eq(result)
      end
    end
  end

  it "can tokenise a sequence of integers and identifiers" do
    file, tokens = tokenise "foo 1 1"
    result = [
      [:identifier, "foo", 0],
      [:integer, "1", 4],
      [:integer, "1", 6]
    ]
    expect(tokens).to eq(result)
  end

  it "can tokenise a multiline statement" do
    file, tokens = tokenise "foo 1 1\n+ 3 3"
    result = [
      [:identifier, "foo", 0],
      [:integer, "1", 4],
      [:integer, "1", 6],
      [:newline, "\n", 7],
      [:identifier, "+", 8],
      [:integer, "3", 10],
      [:integer, "3", 12]
    ]
    expect(tokens).to eq(result)
  end

  it "can tokenise a parenthesized call" do
    file, tokens = tokenise "foo (+ 1 1) 1"
    result = [
      [:identifier, "foo", 0],
      [:left_round_bracket, "(", 4],
      [:identifier, "+", 5],
      [:integer, "1", 7],
      [:integer, "1", 9],
      [:right_round_bracket, ")", 10],
      [:integer, "1", 12]
    ]
    expect(tokens).to eq(result)
  end

  it "can tokenise a definition" do
    file, tokens = tokenise "def foo 12"
    result = [
      [:def, "def", 0],
      [:identifier, "foo", 4],
      [:integer, "12", 8]
    ]
    expect(tokens).to eq(result)
  end

  it "can tokenise array syntax" do
    file, tokens = tokenise "print [1 2]"
    result = [
      [:identifier, "print", 0],
      [:left_square_bracket, "[", 6],
      [:integer, "1", 7],
      [:integer, "2", 9],
      [:right_square_bracket, "]", 10]
    ]
    expect(tokens).to eq(result)
  end

  context "functions" do
    it "can tokenise single line anonymous function syntax" do
      file, tokens = tokenise "fn a -> print a"
      result = [
        [:fn, "fn", 0],
        [:identifier, "a", 3],
        [:arrow, "->", 5],
        [:identifier, "print", 8],
        [:identifier, "a", 14]
      ]
      expect(tokens).to eq(result)
    end

    it "can tokenise single line named function syntax" do
      file, tokens = tokenise "defn say a -> print a"
      result = [
        [:defn, "defn", 0],
        [:identifier, "say", 5],
        [:identifier, "a", 9],
        [:arrow, "->", 11],
        [:identifier, "print", 14],
        [:identifier, "a", 20]
      ]
      expect(tokens).to eq(result)
    end

    it "can tokenise multi-line anonymous function syntax" do
      file, tokens = tokenise "fn a do\n print a\n end"
      result = [
        [:fn, "fn", 0],
        [:identifier, "a", 3],
        [:do, "do", 5],
        [:newline, "\n", 7],
        [:identifier, "print", 9],
        [:identifier, "a", 15],
        [:newline, "\n", 16],
        [:end, "end", 18]
      ]
      expect(tokens).to eq(result)
    end

    it "can tokenise multi-line named function syntax" do
      file, tokens = tokenise "defn say a do \nprint a \n end"
      result = [
        [:defn, "defn", 0],
        [:identifier, "say", 5],
        [:identifier, "a", 9],
        [:do, "do", 11],
        [:newline, "\n", 14],
        [:identifier, "print", 15],
        [:identifier, "a", 21],
        [:newline, "\n", 23],
        [:end, "end", 25]
      ]
      expect(tokens).to eq(result)
    end
  end

  context "true/false/nil" do
    it "can tokenise true" do
      file, tokens = tokenise "true"
      result = [[:true, "true", 0]]
      expect(tokens).to eq(result)
    end
    it "can tokenise false" do
      file, tokens = tokenise "false"
      result = [[:false, "false", 0]]
      expect(tokens).to eq(result)
    end
    it "can tokenise nil" do
      file, tokens = tokenise "nil"
      result = [[:nil, "nil", 0]]
      expect(tokens).to eq(result)
    end
  end

  context "if/unless statements" do
    it "can tokenise an multiline if statement" do
      file, tokens = tokenise "if true do \nprint a \n end"
      result = [[:if, "if", 0],
        [:true, "true", 3],
        [:do, "do", 8],
        [:newline, "\n", 11],
        [:identifier, "print", 12],
        [:identifier, "a", 18],
        [:newline, "\n", 20],
        [:end, "end", 22]]
      expect(tokens).to eq(result)
    end

    it "can tokenise else" do
      file, tokens = tokenise "if true do \nprint a \n else\n print b\n end"
      result = [
        [:if, "if", 0],
        [:true, "true", 3],
        [:do, "do", 8],
        [:newline, "\n", 11],
        [:identifier, "print", 12],
        [:identifier, "a", 18],
        [:newline, "\n", 20],
        [:else, "else", 22],
        [:newline, "\n", 26],
        [:identifier, "print", 28],
        [:identifier, "b", 34],
        [:newline, "\n", 35],
        [:end, "end", 37]]
      expect(tokens).to eq(result)
    end

    it "can tokenise a single line if statement" do
      file, tokens = tokenise "if true -> print a\n"
      result = [[:if, "if", 0],
        [:true, "true", 3],
        [:arrow, "->", 8],
        [:identifier, "print", 11],
        [:identifier, "a", 17],
        [:newline, "\n", 18]]
      expect(tokens).to eq(result)
    end

    it "can tokenise an multiline unless statement" do
      file, tokens = tokenise "unless true do \nprint a \n end"
      result = [[:unless, "unless", 0],
        [:true, "true", 7],
        [:do, "do", 12],
        [:newline, "\n", 15],
        [:identifier, "print", 16],
        [:identifier, "a", 22],
        [:newline, "\n", 24],
        [:end, "end", 26]]
      expect(tokens).to eq(result)
    end

    it "can tokenise else" do
      file, tokens = tokenise "unless true do \nprint a \n else\n print b\n end"
      result = [
        [:unless, "unless", 0],
        [:true, "true", 7],
        [:do, "do", 12],
        [:newline, "\n", 15],
        [:identifier, "print", 16],
        [:identifier, "a", 22],
        [:newline, "\n", 24],
        [:else, "else", 26],
        [:newline, "\n", 30],
        [:identifier, "print", 32],
        [:identifier, "b", 38],
        [:newline, "\n", 39],
        [:end, "end", 41]]
      expect(tokens).to eq(result)
    end

    it "can tokenise a single line unless statement" do
      file, tokens = tokenise "unless true -> print a\n"
      result = [[:unless, "unless", 0],
        [:true, "true", 7],
        [:arrow, "->", 12],
        [:identifier, "print", 15],
        [:identifier, "a", 21],
        [:newline, "\n", 22]]
      expect(tokens).to eq(result)
    end
  end

  context "strings" do
    it "can tokenise a string" do
      file, tokens = tokenise %( "hello world" )
      result = [[:string, "hello world", 1]]
      expect(tokens).to eq(result)
    end

    it "can tokenise a multiple subsequent strings" do
      file, tokens = tokenise %( "hello" "world" )
      result = [[:string, "hello", 1],
        [:string, "world", 9]]
      expect(tokens).to eq(result)
    end
  end

  context "symbols" do
    it "can tokenise a symbol" do
      file, tokens = tokenise ":foo"
      result = [[:symbol, "foo", 0]]
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
