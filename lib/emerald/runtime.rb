module Emerald
  class Runtime
    def define_builtins(env)
      Math.define_builtins(env)
      IO.define_builtins(env)
      Emerald::Types::Array.define_builtins(env)
    end

    class Math
      def self.define_builtins(env)
        [:+, :-, :*, :/, :>, :>=, :<, :<=, :==].each do |op|
          env.set op.to_s,
            Emerald::Types::Function.from_lambda(op.to_s, ->(a, b) { a.send(op, b) })
        end
      end
    end

    class IO
      def self.define_builtins(env)
        env.set 'print', Emerald::Types::Function.from_lambda('print', ->(val) { print val.inspect; val })
        println_fn =
          Emerald::Types::Function.from_block('println', 0..1) do |*args|
            if args.length == 1
              p args[0]
            else
              puts
            end
            args[0]
          end
        env.set 'println', println_fn
      end
    end
  end
end
