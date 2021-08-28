def a "global a"
defn func do
  def b "local b"
  def func2 (fn do
    println a
    println b
  end)
  func2
  def a "local a"
  func2
end

func
