# this is a comment
+ 1 1
println (+ 1 (* 3 4))
def foo 12
def bar 13
println (+ foo bar)
println [1 2 3]
println [1 foo (+ 1 2)]

# anonymous function
def hello (fn a -> print 1)
map hello [1 2 3]
println

# named function
defn square a -> * a a
println (map square [1 2 3 4 5])

# named function
defn print_three a b c -> print [a b c]
print_three 1 2 3
println

# multiline function
defn print_multiline a b c do 
  println a
  println b
  println c
end
print_multiline 9 10 11

println (map (fn a do (* a a) end) [1 2 3 4])
println (map (fn a -> * a a) [1 2 3 4])
println true
println false
println nil

if true do
  println 1 
else
  println 2
end

if true -> println 4
unless false -> println 5

println "Hello World"


