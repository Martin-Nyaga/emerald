defn assert assertion do
  unless assertion -> raise "Assertion failed"
end

defn test str test_fn do
  test_fn
  print "."
end

# Skip a test with xtest
defn xtest str test_fn -> print "S"

# define it/xit as an alias to test/xtest
def it test
def xit xtest

defn describe str describe_fn do
  describe_fn
end

defn suite suite_fn do
  # TODO: Fix this
  println "Running tests..."
  println
  suite_fn
  println
  println
  println "Finished"
end

suite (fn do
  describe "Emerald" (fn do
    it "can evaluate basic math" (fn do
      assert (== (+ 1 1) 2)
      assert (== (+ 1 (* 3 4)) 13)
    end)

    it "can skip over comments" (fn do
      # This is a comment that shouldn't break the interpreter
      assert true
    end)

    it "can define variables and retrieve them" (fn do
      def foo 2
      def bar 3
      assert (== (+ foo bar) 5)
    end)

    # TODO: Test these better once there's array indexing
    it "can evaluate arrays" (fn do
      [1 2 3]
      assert true
    end)

    # TODO: Fix this
    xit "can evaluate anonymous single and multline functions" (fn do
      def inc (fn n -> + n 1)
      def dec (fn n do 
        (- n 1)
      end)
      def arr [1 2 3]
      assert (== (map inc arr) [2 3 4])
      assert (== (map dec arr) [0 1 2])
      assert (== (map (fn a do (* a a) end) arr) [1 4 9])
      assert (== (map (fn a -> * a a) arr) [1 3 9])
    end)

    # TODO: Fix this
    xit "can evaluate named single and multiline functions" (fn do
      defn inc n -> + n 1
      defn dec n do 
        (- n 1)
      end
      def arr [1 2 3]
      assert (== (map inc arr) [2 3 4])
      assert (== (map dec arr) [0 1 2])
    end)

    it "it can evaluate true false and nil" (fn do
      assert true
      assert (unless false -> true)
      assert (unless nil -> true)
    end)

    it "can evaluate single and multiline if/unless statements" (fn do
      # TODO: Allow parens to spill over to next line
      assert (if (== 1 1) do
                true
              else
                false
              end)
      assert (if (== 1 2) do
                false
              else
                true
              end)
      assert (if (== 1 1) -> true)
      assert (unless (== 1 2) do
                true
              else
                false
              end)
      assert (unless (== 1 1) do
                false
              else
                true
              end)
      assert (unless (== 1 2) -> true)
    end)

    it "can parse symbols" (fn do
      assert (== :foo :foo)
    end)

    it "can parse strings" (fn do
      def hi "Hello"
      assert (== hi "Hello")
      # TODO: Fix this
      # assert (== "Hello" "Hello")
    end)
  end)
end)
