# Try/rescue
defn test str test_fn do
  try do
    test_fn
    print "."
  rescue Error (fn e when AssertionFailedError -> print "F"
                     else -> print "E")
end

# Math stdlib
defn sum_square_and_root (x) do
  def square (* x x)
  def root (Math.sqrt x)
  + square root
end
map sum_square_and_root [1 2 3] 

# Modules & symbols
it "can tokenise a parenthesized call" (fn do
  def tokens Emerald::Scanner.tokenise "foo"
  def result [:identifier "foo"]
  Assert.equal tokens result
end)
