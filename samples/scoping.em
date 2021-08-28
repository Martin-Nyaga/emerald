def a "global a"
defn func do
  def b "local b"
  def func2 (fn do
    println a # Should always print "global a"
    println b # Should always print "local b"
  end)
  func2
  def a "local a"
  func2
end

func
