require "spec_helper"
require "emerald/scanner"

describe Emerald::Scanner do
  def tokenise(str)
    file = Emerald::Files::ScriptFile.new(str)
    [file, Emerald::Scanner.new(file).tokens]
  end

  it "can tokenise integers" do
    file,  tokens = tokenise "1"
    expect(tokens).to eq([[:integer, "1", file, 0]])
  end

  context "identifiers" do
    it "allows alphanumeric identifiers tokenise identifiers" do
      file, tokens = tokenise "foo"
      result = [[:identifier, "foo", file, 0]]
      expect(tokens).to eq(result)

      file, tokens = tokenise "foo123"
      result = [[:identifier, "foo123", file, 0]]
      expect(tokens).to eq(result)
    end

    it "allows +-/* as independent identifiers" do
      "+-/*".split("").each do |op|
        file, tokens = tokenise op
        result = [[:identifier, op, file, 0]]
        expect(tokens).to eq(result)
      end
    end
  end

  it "can tokenise a sequence of integers and identifiers" do
    file, tokens = tokenise "foo 1 1"
    result = [
      [:identifier, "foo", file, 0],
      [:integer, "1", file, 4],
      [:integer, "1", file, 6]
    ]
    expect(tokens).to eq(result)
  end

  it "can tokenise a multiline statement" do
    file, tokens = tokenise "foo 1 1\n+ 3 3"
    result = [
      [:identifier, "foo", file, 0],
      [:integer, "1", file, 4],
      [:integer, "1", file, 6],
      [:newline, "\n", file, 7],
      [:identifier, "+", file, 8],
      [:integer, "3", file, 10],
      [:integer, "3", file, 12]
    ]
    expect(tokens).to eq(result)
  end

  it "can tokenise a parenthesized call" do
    file, tokens = tokenise "foo (+ 1 1) 1"
    result = [
      [:identifier, "foo", file, 0],
      [:left_round_bracket, "(", file, 4],
      [:identifier, "+", file, 5],
      [:integer, "1", file, 7],
      [:integer, "1", file, 9],
      [:right_round_bracket, ")", file, 10],
      [:integer, "1", file, 12]
    ]
    expect(tokens).to eq(result)
  end

  it "can tokenise a definition" do
    file, tokens = tokenise "def foo 12"
    result = [
      [:def, "def", file, 0],
      [:identifier, "foo", file, 4],
      [:integer, "12", file, 8]
    ]
    expect(tokens).to eq(result)
  end

  it "can tokenise array syntax" do
    file, tokens = tokenise "print [1 2]"
    result = [
      [:identifier, "print", file, 0],
      [:left_square_bracket, "[", file, 6],
      [:integer, "1", file, 7],
      [:integer, "2", file, 9],
      [:right_square_bracket, "]", file, 10]
    ]
    expect(tokens).to eq(result)
  end

  context "functions" do
    it "can tokenise single line anonymous function syntax" do
      file, tokens = tokenise "fn a -> print a"
      result = [
        [:fn, "fn", file, 0],
        [:identifier, "a", file, 3],
        [:arrow, "->", file, 5],
        [:identifier, "print", file, 8],
        [:identifier, "a", file, 14]
      ]
      expect(tokens).to eq(result)
    end

    it "can tokenise single line named function syntax" do
      file, tokens = tokenise "defn say a -> print a"
      result = [
        [:defn, "defn", file, 0],
        [:identifier, "say", file, 5],
        [:identifier, "a", file, 9],
        [:arrow, "->", file, 11],
        [:identifier, "print", file, 14],
        [:identifier, "a", file, 20]
      ]
      expect(tokens).to eq(result)
    end

    it "can tokenise multi-line anonymous function syntax" do
      file, tokens = tokenise "fn a do\n print a\n end"
      result = [
        [:fn, "fn", file, 0],
        [:identifier, "a", file, 3],
        [:do, "do", file, 5],
        [:newline, "\n", file, 7],
        [:identifier, "print", file, 9],
        [:identifier, "a", file, 15],
        [:newline, "\n", file, 16],
        [:end, "end", file, 18]
      ]
      expect(tokens).to eq(result)
    end

    it "can tokenise multi-line named function syntax" do
      file, tokens = tokenise "defn say a do \nprint a \n end"
      result = [
        [:defn, "defn", file, 0],
        [:identifier, "say", file, 5],
        [:identifier, "a", file, 9],
        [:do, "do", file, 11],
        [:newline, "\n", file, 14],
        [:identifier, "print", file, 15],
        [:identifier, "a", file, 21],
        [:newline, "\n", file, 23],
        [:end, "end", file, 25]
      ]
      expect(tokens).to eq(result)
    end
  end

  context "true/false/nil" do
    it "can tokenise true" do
      file, tokens = tokenise "true"
      result = [[:true, "true", file, 0]]
      expect(tokens).to eq(result)
    end
    it "can tokenise false" do
      file, tokens = tokenise "false"
      result = [[:false, "false", file, 0]]
      expect(tokens).to eq(result)
    end
    it "can tokenise nil" do
      file, tokens = tokenise "nil"
      result = [[:nil, "nil", file, 0]]
      expect(tokens).to eq(result)
    end
  end

  context "if/unless statements" do
    it "can tokenise an multiline if statement" do
      file, tokens = tokenise "if true do \nprint a \n end"
      result = [[:if, "if", file, 0],
        [:true, "true", file, 3],
        [:do, "do", file, 8],
        [:newline, "\n", file, 11],
        [:identifier, "print", file, 12],
        [:identifier, "a", file, 18],
        [:newline, "\n", file, 20],
        [:end, "end", file, 22]]
      expect(tokens).to eq(result)
    end

    it "can tokenise else" do
      file, tokens = tokenise "if true do \nprint a \n else\n print b\n end"
      result = [
        [:if, "if", file, 0],
        [:true, "true", file, 3],
        [:do, "do", file, 8],
        [:newline, "\n", file, 11],
        [:identifier, "print", file, 12],
        [:identifier, "a", file, 18],
        [:newline, "\n", file, 20],
        [:else, "else", file, 22],
        [:newline, "\n", file, 26],
        [:identifier, "print", file, 28],
        [:identifier, "b", file, 34],
        [:newline, "\n", file, 35],
        [:end, "end", file, 37]]
      expect(tokens).to eq(result)
    end

    it "can tokenise a single line if statement" do
      file, tokens = tokenise "if true -> print a\n"
      result = [[:if, "if", file, 0],
        [:true, "true", file, 3],
        [:arrow, "->", file, 8],
        [:identifier, "print", file, 11],
        [:identifier, "a", file, 17],
        [:newline, "\n", file, 18]]
      expect(tokens).to eq(result)
    end

    it "can tokenise an multiline unless statement" do
      file, tokens = tokenise "unless true do \nprint a \n end"
      result = [[:unless, "unless", file, 0],
        [:true, "true", file, 7],
        [:do, "do", file, 12],
        [:newline, "\n", file, 15],
        [:identifier, "print", file, 16],
        [:identifier, "a", file, 22],
        [:newline, "\n", file, 24],
        [:end, "end", file, 26]]
      expect(tokens).to eq(result)
    end

    it "can tokenise else" do
      file, tokens = tokenise "unless true do \nprint a \n else\n print b\n end"
      result = [
        [:unless, "unless", file, 0],
        [:true, "true", file, 7],
        [:do, "do", file, 12],
        [:newline, "\n", file, 15],
        [:identifier, "print", file, 16],
        [:identifier, "a", file, 22],
        [:newline, "\n", file, 24],
        [:else, "else", file, 26],
        [:newline, "\n", file, 30],
        [:identifier, "print", file, 32],
        [:identifier, "b", file, 38],
        [:newline, "\n", file, 39],
        [:end, "end", file, 41]]
      expect(tokens).to eq(result)
    end

    it "can tokenise a single line unless statement" do
      file, tokens = tokenise "unless true -> print a\n"
      result = [[:unless, "unless", file, 0],
        [:true, "true", file, 7],
        [:arrow, "->", file, 12],
        [:identifier, "print", file, 15],
        [:identifier, "a", file, 21],
        [:newline, "\n", file, 22]]
      expect(tokens).to eq(result)
    end
  end

  context "strings" do
    it "can tokenise a string" do
      file, tokens = tokenise %( "hello world" )
      result = [[:string, "hello world", file, 1]]
      expect(tokens).to eq(result)
    end

    it "can tokenise a multiple subsequent strings" do
      file, tokens = tokenise %( "hello" "world" )
      result = [[:string, "hello", file, 1],
        [:string, "world", file, 9]]
      expect(tokens).to eq(result)
    end
  end

  context "symbols" do
    it "can tokenise a symbol" do
      file, tokens = tokenise ":foo"
      result = [[:symbol, "foo", file, 0]]
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
