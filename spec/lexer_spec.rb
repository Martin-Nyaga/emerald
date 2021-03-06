require "spec_helper"
require "emerald/lexer"

describe Emerald::Lexer do
  def tokenise(str)
    file = Emerald::Files::ScriptFile.new(str)
    [file, Emerald::Lexer.new(file).tokens]
  end

  it "can tokenise integers" do
    _, tokens = tokenise "1"
    expect(tokens).to eq([s(:integer, "1", offset: 0)])
  end

  context "identifiers" do
    it "allows alphanumeric identifiers tokenise identifiers" do
      _, tokens = tokenise "foo"
      result = [s(:identifier, "foo", offset: 0)]
      expect(tokens).to eq(result)

      _, tokens = tokenise "foo123"
      result = [s(:identifier, "foo123", offset: 0)]
      expect(tokens).to eq(result)
    end

    it "allows +-/* as independent identifiers" do
      "+-/*".chars.each do |op|
        _, tokens = tokenise op
        result = [s(:identifier, op, offset: 0)]
        expect(tokens).to eq(result)
      end
    end
  end

  it "can tokenise a sequence of integers and identifiers" do
    _, tokens = tokenise "foo 1 1"
    result = [
      s(:identifier, "foo", offset: 0),
      s(:integer, "1", offset: 4),
      s(:integer, "1", offset: 6)
    ]
    expect(tokens).to eq(result)
  end

  it "can tokenise a multiline statement" do
    _, tokens = tokenise "foo 1 1\n+ 3 3"
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
    _, tokens = tokenise "foo (+ 1 1) 1"
    result = [
      s(:identifier, "foo", offset: 0),
      s(:left_paren, "(", offset: 4),
      s(:identifier, "+", offset: 5),
      s(:integer, "1", offset: 7),
      s(:integer, "1", offset: 9),
      s(:right_paren, ")", offset: 10),
      s(:integer, "1", offset: 12)
    ]
    expect(tokens).to eq(result)
  end

  it "can tokenise a definition" do
    _, tokens = tokenise "def foo 12"
    result = [
      s(:def, "def", offset: 0),
      s(:identifier, "foo", offset: 4),
      s(:integer, "12", offset: 8)
    ]
    expect(tokens).to eq(result)
  end

  context "arrays/hashmaps" do
    it "can tokenise array syntax" do
      _, tokens = tokenise "[1 2]"
      result = [
        s(:left_bracket, "[", offset: 0),
        s(:integer, "1", offset: 1),
        s(:integer, "2", offset: 3),
        s(:right_bracket, "]", offset: 4)
      ]
      expect(tokens).to eq(result)
    end

    it "can tokenise hashmap syntax" do
      _, tokens = tokenise "{:foo 1}"
      result = [
        s(:left_brace, "{", offset: 0),
        s(:symbol, "foo", offset: 1),
        s(:integer, "1", offset: 6),
        s(:right_brace, "}", offset: 7)
      ]
      expect(tokens).to eq(result)
    end

    it "allows commas betwen array elements and discards them" do
      _, tokens = tokenise "[1, 2]"
      result = [
        s(:left_bracket, "[", offset: 0),
        s(:integer, "1", offset: 1),
        s(:integer, "2", offset: 4),
        s(:right_bracket, "]", offset: 5)
      ]
      expect(tokens).to eq(result)
    end

    it "allows commas betwen hashmap key value pairs and discards them" do
      _, tokens = tokenise "{:foo 1, :bar 2}"
      result = [
        s(:left_brace, "{", offset: 0),
        s(:symbol, "foo", offset: 1),
        s(:integer, "1", offset: 6),
        s(:symbol, "bar", offset: 9),
        s(:integer, "2", offset: 14),
        s(:right_brace, "}", offset: 15)
      ]
      expect(tokens).to eq(result)
    end
  end

  context "functions" do
    it "can tokenise single line anonymous function syntax" do
      _, tokens = tokenise "fn a -> print a"
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
      _, tokens = tokenise "defn say a -> print a"
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
      _, tokens = tokenise "fn a do\n print a\n end"
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
      _, tokens = tokenise "defn say a do \nprint a \n end"
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
      _, tokens = tokenise "fn a when > 0 a -> print a\nwhen < 0 a -> raise \"foo\""
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
        s(:string, "foo", offset: 47)
      ]
      expect(tokens).to eq(result)
    end
  end

  context "true/false/nil" do
    it "can tokenise true" do
      _, tokens = tokenise "true"
      result = [s(:true, "true", offset: 0)]
      expect(tokens).to eq(result)
    end
    it "can tokenise false" do
      _, tokens = tokenise "false"
      result = [s(:false, "false", offset: 0)]
      expect(tokens).to eq(result)
    end
    it "can tokenise nil" do
      _, tokens = tokenise "nil"
      result = [s(:nil, "nil", offset: 0)]
      expect(tokens).to eq(result)
    end
  end

  context "if/unless statements" do
    it "can tokenise an multiline if statement" do
      _, tokens = tokenise "if true do \nprint a \n end"
      result = [s(:if, "if", offset: 0),
        s(:true, "true", offset: 3),
        s(:do, "do", offset: 8),
        s(:newline, "\n", offset: 11),
        s(:identifier, "print", offset: 12),
        s(:identifier, "a", offset: 18),
        s(:newline, "\n", offset: 20),
        s(:end, "end", offset: 22)]
      expect(tokens).to eq(result)
    end

    it "can tokenise else" do
      _, tokens = tokenise "if true do \nprint a \n else\n print b\n end"
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
      _, tokens = tokenise "if true -> print a\n"
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
      _, tokens = tokenise "unless true do \nprint a \n end"
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
      _, tokens = tokenise "unless true do \nprint a \n else\n print b\n end"
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
      _, tokens = tokenise "unless true -> print a\n"
      result = [s(:unless, "unless", offset: 0),
        s(:true, "true", offset: 7),
        s(:arrow, "->", offset: 12),
        s(:identifier, "print", offset: 15),
        s(:identifier, "a", offset: 21),
        s(:newline, "\n", offset: 22)]
      expect(tokens).to eq(result)
    end
  end

  context "strings" do
    it "can tokenise a string" do
      _, tokens = tokenise %( "hello world" )
      result = [s(:string, "hello world", offset: 1)]
      expect(tokens).to eq(result)
    end

    it "can tokenise a multiple subsequent strings" do
      _, tokens = tokenise %( "hello" "world" )
      result = [
        s(:string, "hello", offset: 1),
        s(:string, "world", offset: 9)
      ]
      expect(tokens).to eq(result)
    end
  end

  context "symbols" do
    it "can tokenise a symbol" do
      _, tokens = tokenise ":foo"
      result = [s(:symbol, "foo", offset: 0)]
      expect(tokens).to eq(result)
    end
  end

  context "comments" do
    it "can skip over comments in the Lexer" do
      _, tokens = tokenise "# this is a comment"
      result = []
      expect(tokens).to eq(result)
    end
  end

  context "invalid tokens" do
    it "returns a clear syntax error when an invalid token is detected" do
      expect { tokenise "def @ foo" }.to raise_error(Emerald::SyntaxError)
    end
  end

  context "constants" do
    it "can tokenise constants" do
      _, tokens = tokenise "String"
      result = [s(:constant, "String", offset: 0)]
      expect(tokens).to eq(result)
    end
  end

  context "Types" do
    it "can tokenise deftype as a keyword" do
      _, tokens = tokenise "deftype MyError"
      result = [s(:deftype, "deftype", offset: 0), s(:constant, "MyError", offset: 8)]
      expect(tokens).to eq(result)
    end
  end

  context "Modules" do
    it "can tokenise defmodule as a keyword" do
      _, tokens = tokenise "defmodule M do end"
      result = [
        s(:defmodule, "defmodule", offset: 0),
        s(:constant, "M", offset: 10),
        s(:do, "do", offset: 12),
        s(:end, "end", offset: 15)
      ]
      expect(tokens).to eq(result)
    end

    it "can tokenise module scoped identifiers" do
      _, tokens = tokenise "M.foo"
      result = [
        s(:constant, "M", offset: 0),
        s(:dot, ".", offset: 1),
        s(:identifier, "foo", offset: 2)
      ]
      expect(tokens).to eq(result)
    end

    it "can tokenise module scoped constants" do
      _, tokens = tokenise "M::Foo"
      result = [
        s(:constant, "M", offset: 0),
        s(:double_colon, "::", offset: 1),
        s(:constant, "Foo", offset: 3)
      ]
      expect(tokens).to eq(result)
    end
  end

  context "References" do
    it "can tokenise &refernce" do
      _, tokens = tokenise "&String"
      result = [s(:ref, "&", offset: 0), s(:constant, "String", offset: 1)]
      expect(tokens).to eq(result)
    end
  end

  context "Imports" do
    it "can tokenise import as a keyword" do
      _, tokens = tokenise %(import "test")
      result = [s(:import, "import", offset: 0), s(:string, "test", offset: 7)]
      expect(tokens).to eq(result)
    end
  end
end
