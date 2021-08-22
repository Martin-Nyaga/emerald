
fn (a b c) => a + b + c

defn sum_square_and_root (x) do
  def square (* x x)
  def root (Math.sqrt x)
  + square root
end
map sum_square_and_root [1 2 3] 

defn foo fn (a b c) do
  print "Hello World"
end

print_three 1 2 3

describe "MyModule" do
  context "MyThing" do
    it "Can do the thing I want" do
      Assert.assert (foo bar baz)
    end
  end 
end

defn fib (x) 
  when x == 0 => 0
  when x == 1 => 1
  else => + (fib (- x 1)) (fib (- x 2))
end

defn fizbuzz n

it "can tokenise a parenthesized call" do
  def tokens Emerald::Scanner.tokenise "foo"
  def result [:identifier "foo"]
  Assert.equal tokens result
end

module Emerald do
  module Token
    def types [
      [:define /def/]
      [:identifier /.../]
    ]

    defn match token text
      def pattern last (token_type)
      Regex.match pattern text #=> { :length 12 :is_keyword false }
    end
  end

  module Scanner do
    defn tokenise text do
      def match last sorted_maches
      if match do
        next_match match text
      else
        raise SyntaxError "Unexpected input"
      end
    end

    defn next_match match text do
      concat match (tokenise (String.substring text (:length match) (String.length text)))
    end

    defn sorted_matches text do
      Token.types
        |> map (fn token => Token.match token text)
        |> filter (fn match => > (:length match) 0)
        |> sort (fn match => [(:length match) (:is_keyword match)])
    end
  end
end
