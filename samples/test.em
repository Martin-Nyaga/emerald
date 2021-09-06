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

# define it/xit as an alias to test/xtest
def it &test
def xit &xtest

defn describe str describe_fn do
  describe_fn
end

defn suite suite_fn do
  println "Running tests:"
  suite_fn
  println
  println
  println "Finished!"
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
    it "can evaluate anonymous single and multline functions" (fn do
      def inc (fn n -> + n 1)
      def dec (fn n do 
        (- n 1)
      end)
      def arr [1 2 3]
      assert (== (map &inc arr) [2 3 4])
      assert (== (map &dec arr) [0 1 2])
      assert (== (map (fn a do (* a a) end) arr) [1 4 9])
      assert (== (map (fn a -> * a a) arr) [1 4 9])
    end)

    it "can evaluate named single and multiline functions" (fn do
      defn inc n -> + n 1
      defn dec n do 
        (- n 1)
      end
      def arr [1 2 3]
      assert (== (map &inc arr) [2 3 4])
      assert (== (map &dec arr) [0 1 2])
    end)

    it "it can evaluate true false and nil" (fn do
      assert true
      assert (unless false -> true)
      assert (unless nil -> true)
    end)

    it "can evaluate single and multiline if/unless statements" (fn do
      # TODO: Allow parens to spill over to next line
      assert (if == 1 1 do
                true
              else
                false
              end)
      assert (if == 1 2 do
                false
              else
                true
              end)
      assert (if == 1 1 -> true)
      assert (unless == 1 2 do
                true
              else
                false
              end)
      assert (unless == 1 1 do
                false
              else
                true
              end)
      assert (unless == 1 2 -> true)
    end)

    it "can parse symbols" (fn do
      assert (== :foo :foo)
    end)

    it "can parse strings" (fn do
      def hi "Hello"
      assert (== hi "Hello")
      assert (== "Hello" "Hello")
    end)

    it "can evaluate guarded functions" (fn do
      defn even? x
        when == 0 (% x 2) -> true
        when == 1 (% x 2) -> false
      end

      assert (even? 8)
      assert (== false (even? 3))
    end)

    it "correctly scopes variables in closures" (fn do
      def a "outer a"
      defn func do
        def b "inner b"
        def func2 (fn do
          assert (== a "outer a")
          assert (== b "inner b")
        end)
        func2
        def a "inner a"
        func2
      end
      func
    end)

    it "understands basic types" (fn do
      assert (== &String (type "hello"))
      assert (== &Integer (type 1))
      assert (== &Array (type [1 2 3]))
      assert (== &Function (type (fn do end)))
      assert (== &Nil (type nil))
    end)

    it "can parse hashmaps" (fn do
      def a {:foo "bar" :baz "buz"}
      assert (== (:foo a) "bar")
    end)
    
    it "skips over commas as whitespace" (fn do
      def a {:foo "bar", :baz "buz"}
      def b [1, 2, 3, 4]
    end)

    it "can define a type" (fn do
      deftype MyError1
      # TODO: Revisit once we have some kind of base Type
    end)

    it "can define a subtype" (fn do
      deftype MyError2 Error
      assert (== &Error (super &MyError2))
    end)

    it "can reference a function" (fn do
      defn foo -> nil
      def foo_ref &foo
      assert (== &Function (type &foo))
      assert (== &Function (type &foo_ref))
    end)
  end)
end)
