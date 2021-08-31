it "can define basic record types" (fn do
  deftype User () [:email, :first_name, :last_name]
  def john (User { :email "test@example.com", :first_name "John", :last_name "Doe"})
  assert (== (:first_name john) "John")
  assert (== (:last_name john) "Doe")
end)

# Try/rescue
defn test str test_fn do
  try do
    test_fn
    print "."
  rescue Error (fn e 
    when AssertionFailedError -> print "F"
    else -> print "E"
    end)
  end
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
