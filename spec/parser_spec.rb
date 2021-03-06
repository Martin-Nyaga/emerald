require "spec_helper"

describe Emerald::Parser do
  def parse str
    file = Emerald::Files::ScriptFile.new(str)
    tokens = Emerald::Lexer.new(file).tokens
    Emerald::Parser.new(file, tokens).parse
  end

  context "empty" do
    it "can parse an empty list of tokens" do
      expect(parse("")).to eq(s(:block, offset: 0))
    end
  end

  context "terminal" do
    it "can parse an integer" do
      src = "1"
      result = s(:block, s(:integer, "1", offset: 0))
      expect(parse(src)).to eq(result)
    end

    it "can parse a string" do
      src = %( "hello world" )
      result = s(:block, s(:string, "hello world", offset: 1), offset: 0)
      expect(parse(src)).to eq(result)
    end

    it "can parse a symbol" do
      src = ":foo"
      result = s(:block, s(:symbol, "foo", offset: 0))
      expect(parse(src)).to eq(result)
    end
  end

  context "call" do
    it "can parse a call" do
      src = "foo 1 1"
      result =
        s(:block,
          s(:call,
            s(:identifier, "foo", offset: 0), s(:integer, "1", offset: 4), s(:integer, "1", offset: 6)))
      expect(parse(src)).to eq(result)
    end

    it "can parse a call with identifiers" do
      src = "foo bar baz"
      result =
        s(:block,
          s(:call,
            s(:identifier, "foo", offset: 0), s(:identifier, "bar", offset: 4), s(:identifier, "baz", offset: 8)))
      expect(parse(src)).to eq(result)
    end

    it "can parse a call with a symbol" do
      src = ":a {:a 1}"
      result =
        s(:block,
          s(:call,
            s(:symbol, "a", offset: 0),
            s(:hashmap, s(:symbol, "a", offset: 4), s(:integer, "1", offset: 7), offset: 3)))
      expect(parse(src)).to eq(result)
    end
  end

  context "multiline" do
    it "can parse a multiline program" do
      src = "foo 1 1\nbar 1 1"
      result =
        s(:block,
          s(:call, s(:identifier, "foo", offset: 0), s(:integer, "1", offset: 4), s(:integer, "1", offset: 6)),
          s(:call, s(:identifier, "bar", offset: 8), s(:integer, "1", offset: 12), s(:integer, "1", offset: 14)))
      expect(parse(src)).to eq(result)
    end
  end

  context "parenthesized" do
    it "can parse a parenthesized call" do
      src = "foo (+ 1 1) 1"
      result =
        s(:block,
          s(:call, s(:identifier, "foo", offset: 0),
            s(:call, s(:identifier, "+", offset: 5), s(:integer, "1", offset: 7), s(:integer, "1", offset: 9)),
            s(:integer, "1", offset: 12)))
      expect(parse(src)).to eq(result)
    end

    it "raises a syntax error for unclosed parens" do
      src = "foo ("
      expect { parse src }.to raise_error(Emerald::SyntaxError)
    end
  end

  context "def" do
    it "can parse a definition call" do
      src = "def foo 12"
      result = s(:block, s(:def, s(:identifier, "foo", offset: 4), s(:integer, "12", offset: 8), offset: 0), offset: 0)
      expect(parse(src)).to eq(result)
    end
  end

  context "array" do
    it "can parse array syntax" do
      src = "print [1 2]"
      result = s(:block, s(:call, s(:identifier, "print", offset: 0), s(:array, s(:integer, "1", offset: 7), s(:integer, "2", offset: 9), offset: 6)))
      expect(parse(src)).to eq(result)
    end

    it "raises a syntax error for unclosed square brackets" do
      src = "foo ["
      expect { parse src }.to raise_error(Emerald::SyntaxError)
    end
  end

  context "hashmap" do
    it "can parse hashmap syntax" do
      src = "print { :foo 1 }"
      result =
        s(:block,
          s(:call,
            s(:identifier, "print", offset: 0),
            s(:hashmap, s(:symbol, "foo", offset: 8), s(:integer, "1", offset: 13), offset: 6)))
      expect(parse(src)).to eq(result)
    end

    it "raises a syntax error for unclosed brace" do
      src = "foo {"
      expect { parse src }.to raise_error(Emerald::SyntaxError)
    end

    it "raises a syntax error for incomplete key-value pair" do
      src = "{ :foo }"
      expect { parse src }.to raise_error(Emerald::SyntaxError)
    end
  end

  context "functions" do
    it "can parse a single line anonymous function definition" do
      src = "fn a -> print a"
      result = s(:block,
        s(:fn,
          s(:params, s(:identifier, "a", offset: 3)),
          s(:block, s(:call, s(:identifier, "print", offset: 8), s(:identifier, "a", offset: 14)), offset: 5), offset: 0), offset: 0)
      expect(parse(src)).to eq(result)
    end

    it "can parse a single line named function definition" do
      src = "defn say a -> print a"
      result = s(:block,
        s(:defn,
          s(:identifier, "say", offset: 5),
          s(:params, s(:identifier, "a", offset: 9)),
          s(:block, s(:call, s(:identifier, "print", offset: 14), s(:identifier, "a", offset: 20)), offset: 11), offset: 0), offset: 0)
      expect(parse(src)).to eq(result)
    end

    it "can parse a multi-line anonymous function definition" do
      src = "fn a b do\n print a\nprint b\n end"
      result = s(:block,
        s(:fn,
          s(:params, s(:identifier, "a", offset: 3), s(:identifier, "b", offset: 5)),
          s(:block,
            s(:call, s(:identifier, "print", offset: 11), s(:identifier, "a", offset: 17)),
            s(:call, s(:identifier, "print", offset: 19), s(:identifier, "b", offset: 25)),
            offset: 7),
          offset: 0),
        offset: 0)
      expect(parse(src)).to eq(result)
    end

    it "can parse a multi-line named function definition" do
      src = "defn say a b do\n print a \n print b\n end"
      result = s(:block,
        s(:defn,
          s(:identifier, "say", offset: 5),
          s(:params, s(:identifier, "a", offset: 9), s(:identifier, "b", offset: 11)),
          s(:block,
            s(:call, s(:identifier, "print", offset: 17), s(:identifier, "a", offset: 23)),
            s(:call, s(:identifier, "print", offset: 27), s(:identifier, "b", offset: 33)),
            offset: 13),
          offset: 0),
        offset: 0)
      expect(parse(src)).to eq(result)
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

    it "raises a syntax error for improperly delimited expressions in a function body" do
      src = "defn bar do Bar Baz end"
      expect { parse src }.to raise_error(Emerald::SyntaxError)
    end

    it "can parse a function guard" do
      src = "fn a when > 0 a -> print a\nwhen < 0 a -> raise \"foo\" end"
      result =
        s(:block,
          s(:fn,
            s(:params, s(:identifier, "a", offset: 3)),
            s(:guards,
              s(:when,
                s(:call, s(:identifier, ">", offset: 10), s(:integer, "0", offset: 12), s(:identifier, "a", offset: 14)),
                s(:block, s(:call, s(:identifier, "print", offset: 19), s(:identifier, "a", offset: 25)), offset: 16),
                offset: 5),
              s(:when,
                s(:call, s(:identifier, "<", offset: 32), s(:integer, "0", offset: 34), s(:identifier, "a", offset: 36)),
                s(:block, s(:call, s(:identifier, "raise", offset: 41), s(:string, "foo", offset: 47)), offset: 38),
                offset: 27),
              offset: 5),
            offset: 0),
          offset: 0)
      expect(parse(src)).to eq(result)
    end

    it "can parse a function guard with an else clause" do
      src = "fn a when > 0 a -> print a\nelse -> raise \"foo\" end"
      result =
        s(:block,
          s(:fn,
            s(:params, s(:identifier, "a", offset: 3)),
            s(:guards,
              s(:when,
                s(:call, s(:identifier, ">", offset: 10), s(:integer, "0", offset: 12), s(:identifier, "a", offset: 14)),
                s(:block, s(:call, s(:identifier, "print", offset: 19), s(:identifier, "a", offset: 25)), offset: 16),
                offset: 5),
              s(:when,
                s(:true, "else", offset: 27),
                s(:block, s(:call, s(:identifier, "raise", offset: 35), s(:string, "foo", offset: 41)), offset: 32)),
              offset: 5),
            offset: 0),
          offset: 0)
      expect(parse(src)).to eq(result)
    end
  end

  context "true/false/nil" do
    it "can parse true" do
      src = "true"
      result = s(:block, s(:true, "true", offset: 0))
      expect(parse(src)).to eq(result)
    end

    it "can parse false" do
      src = "false"
      result = s(:block, s(:false, "false", offset: 0))
      expect(parse(src)).to eq(result)
    end

    it "can parse nil" do
      src = "nil"
      result = s(:block, s(:nil, "nil", offset: 0))
      expect(parse(src)).to eq(result)
    end
  end

  context "if/unless statement" do
    it "can parse a multiline if statement" do
      src = "if true do\n print a \nend"
      result = s(:block,
        s(:if, s(:true, "true", offset: 3),
          s(:block, s(:call, s(:identifier, "print", offset: 12), s(:identifier, "a", offset: 18))),
          s(:block), offset: 0), offset: 0)
      expect(parse(src)).to eq(result)
    end

    it "can parse a multiline if else" do
      src = "if true do\n print a \nelse \nprint b \n end"
      result = s(:block,
        s(:if, s(:true, "true", offset: 3),
          s(:block, s(:call, s(:identifier, "print", offset: 12), s(:identifier, "a", offset: 18))),
          s(:block, s(:call, s(:identifier, "print", offset: 27), s(:identifier, "b", offset: 33))), offset: 0), offset: 0)
      expect(parse(src)).to eq(result)
    end

    it "can parse a single line if statement" do
      src = "if true -> print a"
      result = s(:block,
        s(:if, s(:true, "true", offset: 3),
          s(:block, s(:call, s(:identifier, "print", offset: 11), s(:identifier, "a", offset: 17)), offset: 8),
          s(:block), offset: 0), offset: 0)
      expect(parse(src)).to eq(result)
    end

    it "can parse a multiline unless statement" do
      src = "unless true do\n print a \nend"
      result = s(:block,
        s(:unless, s(:true, "true", offset: 7),
          s(:block, s(:call, s(:identifier, "print", offset: 16), s(:identifier, "a", offset: 22))),
          s(:block), offset: 0), offset: 0)
      expect(parse(src)).to eq(result)
    end

    it "can parse a multiline unless else" do
      src = "unless true do\n print a \nelse \nprint b \n end"
      result = s(:block,
        s(:unless, s(:true, "true", offset: 7),
          s(:block, s(:call, s(:identifier, "print", offset: 16), s(:identifier, "a", offset: 22))),
          s(:block, s(:call, s(:identifier, "print", offset: 31), s(:identifier, "b", offset: 37))), offset: 0), offset: 0)
      expect(parse(src)).to eq(result)
    end

    it "can parse a single line unless statement" do
      src = "unless true -> print a"
      result =
        s(:block,
          s(:unless, s(:true, "true", offset: 7),
            s(:block, s(:call, s(:identifier, "print", offset: 15), s(:identifier, "a", offset: 21)), offset: 12),
            s(:block), offset: 0), offset: 0)
      expect(parse(src)).to eq(result)
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

  context "Types" do
    it "can parse an empty type definition" do
      src = "deftype MyError"
      result = s(:block,
        s(:deftype,
          s(:constant, "MyError", offset: 8),
          s(:nil, "nil", offset: 14),
          s(:array, offset: 14), offset: 0))
      expect(parse(src)).to eq(result)
    end

    it "can parse a subtype definition" do
      src = "deftype MyError Error"
      result = s(:block,
        s(:deftype,
          s(:constant, "MyError", offset: 8),
          s(:constant, "Error", offset: 16),
          s(:array, offset: 20), offset: 0))
      expect(parse(src)).to eq(result)
    end

    it "can parse a type definition with fields" do
      src = "deftype User [:name :email]"
      result = s(:block,
        s(:deftype,
          s(:constant, "User", offset: 8),
          s(:nil, "nil", offset: 13),
          s(:array,
            s(:symbol, "name", offset: 14),
            s(:symbol, "email", offset: 20), offset: 13), offset: 0))
      expect(parse(src)).to eq(result)
    end

    it "can parse type constructors" do
      src = %(Error "an error occured")
      result = s(:block,
        s(:constructor,
          s(:constant, "Error", offset: 0),
          s(:string, "an error occured", offset: 6),
          offset: 0),
        offset: 0)
      expect(parse(src)).to eq(result)
    end
  end

  context "References" do
    it "can parse a reference" do
      src = "&String"
      result = s(:block, s(:ref, s(:constant, "String", offset: 1), offset: 0), offset: 0)
      expect(parse(src)).to eq(result)
    end

    it "raises a syntax error on an invalid reference" do
      src = "&"
      expect { parse src }.to raise_error(Emerald::SyntaxError)

      src = "&[1 2 3]"
      expect { parse src }.to raise_error(Emerald::SyntaxError)
    end
  end

  context "Imports" do
    it "can parse imports" do
      src = %(import "test")
      result = s(:block, s(:import, s(:string, "test", offset: 7), offset: 0))
      expect(parse(src)).to eq(result)
    end
  end

  context "Module" do
    it "can parse a module definition" do
      src = "defmodule M do end"
      result = s(:block,
        s(:defmodule,
          s(:constant, "M", offset: 10),
          s(:block, offset: 12), offset: 0), offset: 0)
      expect(parse(src)).to eq(result)
    end

    it "can parse a module scoped identifier" do
      src = "M.foo"
      result = s(:block,
        s(:call,
          s(:module_scoped_identifier,
            s(:constant, "M", offset: 0),
            s(:identifier, "foo", offset: 2),
            offset: 0),
          offset: 0),
        offset: 0)
      expect(parse(src)).to eq(result)
    end

    it "can parse a module scoped identifier in a symbol call" do
      src = ":a M.foo"
      result =
        s(:block,
          s(:call,
            s(:symbol, "a", offset: 0),
            s(:module_scoped_identifier,
              s(:constant, "M", offset: 3),
              s(:identifier, "foo", offset: 5))))
      expect(parse(src)).to eq(result)
    end

    it "can parse a module scoped constant" do
      src = "M::Foo"
      result = s(:block,
        s(:constructor,
        s(:module_scoped_constant,
          s(:constant, "M", offset: 0),
          s(:constant, "Foo", offset: 3))))
      expect(parse(src)).to eq(result)
    end
  end
end
