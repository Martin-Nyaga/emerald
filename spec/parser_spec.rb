require "spec_helper"

describe Emerald::Parser do
  def parse str
    file = Emerald::Files::ScriptFile.new(str)
    tokens = Emerald::Scanner.new(file).tokens
    Emerald::Parser.new(file, tokens).parse
  end

  context "empty" do
    it "can parse an empty list of tokens" do
      expect(parse "").to eq(s(:block))
    end
  end

  context "terminal" do
    it "can parse an integer" do
      src = "1"
      result = s(:block, s(:integer, "1", offset: 0))
      expect(parse src).to eq(result)
    end

    it "can parse a string" do
      src = %( "hello world" )
      result = s(:block, s(:string, "hello world", offset: 1))
      expect(parse src).to eq(result)
    end

    it "can parse a symbol" do
      src = ":foo"
      result = s(:block, s(:symbol, "foo", offset: 0))
      expect(parse src).to eq(result)
    end
  end

  context "call" do
    it "can parse a call" do
      src = "foo 1 1"
      result =
        s(:block,
          s(:call,
            s(:identifier, "foo", offset: 0), s(:integer, "1", offset: 4), s(:integer, "1", offset: 6)))
      expect(parse src).to eq(result)
    end

    it "can parse a call with identifiers" do
      src = "foo bar baz"
      result =
        s(:block,
          s(:call,
            s(:identifier, "foo", offset: 0), s(:identifier, "bar", offset: 4), s(:identifier, "baz", offset: 8)))
      expect(parse src).to eq(result)
    end
  end

  context "multiline" do
    it "can parse a multiline program" do
      src = "foo 1 1\nbar 1 1"
      result =
        s(:block,
          s(:call, s(:identifier, "foo", offset: 0), s(:integer, "1", offset: 4), s(:integer, "1", offset: 6)),
          s(:call, s(:identifier, "bar", offset: 8), s(:integer, "1", offset: 12), s(:integer, "1", offset: 14)))
      expect(parse src).to eq(result)
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
      result = s(:block, s(:def, s(:identifier, "foo", offset: 4), s(:integer, "12", offset: 8)))
      expect(parse src).to eq(result)
    end
  end

  context "array" do
    it "can parse array syntax" do
      src = "print [1 2]"
      result = s(:block, s(:call, s(:identifier, "print", offset: 0), s(:array, s(:integer, "1", offset: 7), s(:integer, "2", offset: 9))))
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
      result = s(:block,
        s(:fn,
          s(:params, s(:identifier, "a", offset: 3)),
          s(:block, s(:call, s(:identifier, "print", offset: 8), s(:identifier, "a", offset: 14)))))
      expect(parse src).to eq(result)
    end

    it "can parse a single line named function definition" do
      src = "defn say a -> print a"
      result = s(:block,
        s(:defn,
          s(:identifier, "say", offset: 5),
          s(:params, s(:identifier, "a", offset: 9)),
          s(:block, s(:call, s(:identifier, "print", offset: 14), s(:identifier, "a", offset: 20)))))
      expect(parse src).to eq(result)
    end

    it "can parse a multi-line anonymous function definition" do
      src = "fn a b do\n print a\nprint b\n end"
      result = s(:block,
        s(:fn,
          s(:params, s(:identifier, "a", offset: 3), s(:identifier, "b", offset: 5)),
          s(:block,
            s(:call, s(:identifier, "print", offset: 11), s(:identifier, "a", offset: 17)),
            s(:call, s(:identifier, "print", offset: 19), s(:identifier, "b", offset: 25)))))
      expect(parse src).to eq(result)
    end

    it "can parse a multi-line named function definition" do
      src = "defn say a b do\n print a \n print b\n end"
      result = s(:block,
        s(:defn,
          s(:identifier, "say", offset: 5),
          s(:params, s(:identifier, "a", offset: 9), s(:identifier, "b",  offset: 11)),
          s(:block,
            s(:call, s(:identifier, "print", offset: 17), s(:identifier, "a", offset: 23)),
            s(:call, s(:identifier, "print", offset: 27), s(:identifier, "b", offset: 33)))))
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

    it "can parse a function guard" do
      src = "fn a when > 0 a -> print a\nwhen < 0 a -> raise \"foo\" end"
      result =
        s(:block,
          s(:fn,
            s(:params, s(:identifier, "a", offset: 3)),
            s(:guards,
              s(:when,
                s(:call, s(:identifier, ">", offset: 10), s(:integer, "0", offset: 12), s(:identifier, "a", offset: 14)),
                s(:block, s(:call, s(:identifier, "print", offset: 19), s(:identifier, "a", offset: 25)))),
              s(:when,
                s(:call, s(:identifier, "<", offset: 32), s(:integer, "0", offset: 34), s(:identifier, "a", offset: 36)),
                s(:block, s(:call, s(:identifier, "raise", offset: 41), s(:string, "foo", offset: 47)))))))
      expect(parse src).to eq(result)
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
                s(:block, s(:call, s(:identifier, "print", offset: 19), s(:identifier, "a", offset: 25)))),
              s(:when,
                s(:true, "else", offset:27),
                s(:block, s(:call, s(:identifier, "raise", offset: 35), s(:string, "foo", offset: 41)))))))
      expect(parse src).to eq(result)
    end
  end

  context "true/false/nil" do
    it "can parse true" do
      src = "true"
      result = s(:block, s(:true, "true", offset: 0))
      expect(parse src).to eq(result)
    end

    it "can parse false" do
      src = "false"
      result = s(:block, s(:false, "false", offset: 0))
      expect(parse src).to eq(result)
    end

    it "can parse nil" do
      src = "nil"
      result = s(:block, s(:nil, "nil", offset: 0))
      expect(parse src).to eq(result)
    end
  end

  context "if/unless statement" do
    it "can parse a multiline if statement" do
      src = "if true do\n print a \nend"
      result = s(:block,
        s(:if, s(:true, "true", offset: 3),
          s(:block, s(:call, s(:identifier, "print", offset: 12), s(:identifier, "a", offset: 18))),
          s(:block)))
      expect(parse src).to eq(result)
    end

    it "can parse a multiline if else" do
      src = "if true do\n print a \nelse \nprint b \n end"
      result = s(:block,
        s(:if, s(:true, "true", offset: 3),
          s(:block, s(:call, s(:identifier, "print", offset: 12), s(:identifier, "a", offset: 18))),
          s(:block, s(:call, s(:identifier, "print", offset: 27), s(:identifier, "b", offset: 33)))))
      expect(parse src).to eq(result)
    end

    it "can parse a single line if statement" do
      src = "if true -> print a"
      result = s(:block,
        s(:if, s(:true, "true", offset: 3),
          s(:block, s(:call, s(:identifier, "print", offset: 11), s(:identifier, "a", offset: 17))),
          s(:block)))
      expect(parse src).to eq(result)
    end

    it "can parse a multiline unless statement" do
      src = "unless true do\n print a \nend"
      result = s(:block,
        s(:unless, s(:true, "true", offset: 7),
          s(:block, s(:call, s(:identifier, "print", offset: 16), s(:identifier, "a", offset: 22))),
          s(:block)))
      expect(parse src).to eq(result)
    end

    it "can parse a multiline unless else" do
      src = "unless true do\n print a \nelse \nprint b \n end"
      result = s(:block,
        s(:unless, s(:true, "true", offset: 7),
          s(:block, s(:call, s(:identifier, "print", offset: 16), s(:identifier, "a", offset: 22))),
          s(:block, s(:call, s(:identifier, "print", offset: 31), s(:identifier, "b", offset: 37)))))
      expect(parse src).to eq(result)
    end

    it "can parse a single line unless statement" do
      src = "unless true -> print a"
      result =
        s(:block,
          s(:unless, s(:true, "true", offset: 7),
            s(:block, s(:call, s(:identifier, "print", offset: 15), s(:identifier, "a", offset: 21))),
            s(:block)))
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
