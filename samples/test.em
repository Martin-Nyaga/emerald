+ 1 1
println (+ 1 (* 3 4))
def foo 12
def bar 13
println (+ foo bar)
println [1 2 3]
println [1 foo (+ 1 2)]

def hello (fn a => println 1)
map hello [1 2 3]
println

defn square a => * a a
println (map square [1 2 3 4 5])
