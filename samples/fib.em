defn fib n do
  if (<= n 1) do
    1
  else
    + (fib (- n 1)) (fib (- n 2))
  end
end

defn fib_with_guards n
  when <= n 1 -> 1
  else -> + (fib_with_guards (- n 1)) (fib_with_guards (- n 2))
end

println "Without guards"
def nums [0 1 2 3 4 5 6 7 8 9 10]
println (map fib nums)

println "With guards"
def nums [0 1 2 3 4 5 6 7 8 9 10]
println (map fib_with_guards nums)
