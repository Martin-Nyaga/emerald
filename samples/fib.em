def fib n do
  if (<= n 1) do
    1
  else
    + (fib (- n 1)) (fib (- n 2))
  end
end

def nums [0 1 2 3 4 5 6 7 8 9 10]
println (map fib nums)
