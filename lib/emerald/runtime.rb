module Emerald
  class Runtime
    def define_builtins(env)
      Math.define_builtins(env)
      IO.define_builtins(env)
      Emerald::Types::Array.define_builtins(env)
      Error.define_builtins(env)
    end

    class Math
      def self.define_builtins(env)
        [:+, :-, :*, :/, :>, :>=, :<, :<=, :==].each do |op|
          env.set op.to_s,
            Emerald::Types::Function.from_lambda(op.to_s, ->(_, _, a, b) {
              a.send(op, b)
            })
        end
      end
    end

    class IO
      def self.define_builtins(env)
        env.set 'print', (Emerald::Types::Function.from_block('print', 0..) do |_, _, *vals|
           print *vals
           nil
        end)

        env.set 'println', (Emerald::Types::Function.from_block('println', 0..) do |_, _, *args|
          if args.length > 0
            print *args
            puts
          else
            puts
          end
          nil
        end)
      end
    end

    class Error
      def self.define_builtins(env)
        env.set "raise", Emerald::Types::Function.from_lambda('raise', -> (_, _, err) { raise err })
      end
    end
  end
end
