deftype AssertionError Error

defn assert assertion do
  unless assertion -> raise (AssertionError "Assertion failed")
end

defn test str test_fn do
  test_fn
  print "."
end

# Skip a test with xtest
defn xtest str test_fn -> print "S"

# it/xit is an alias to test/xtest
def it &test
def xit &xtest

defn describe str describe_fn do
  describe_fn
end
