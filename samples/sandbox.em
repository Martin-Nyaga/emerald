# Comments

# Math stdlib
defn sum_square_and_root (x) do
  def square (* x x)
  def root (Math.sqrt x)
  + square root
end
map sum_square_and_root [1 2 3] 


# Function guards
defn fib (x) 
  when == 0 x => 0
  when == 1 x => 1
  else        => + (fib (- x 1)) (fib (- x 2))
end

# Blocks
describe "MyModule" do
  context "MyThing" do
    it "Can do the thing I want" do
      Assert.assert (foo bar baz)
    end
  end 
end

# Modules & symbols
it "can tokenise a parenthesized call" do
  def tokens Emerald::Scanner.tokenise "foo"
  def result [:identifier "foo"]
  Assert.equal tokens result
end
