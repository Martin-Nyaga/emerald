module Emerald
  module Types
    def self.assert_type(env, arg, type, message = nil)
      unless arg.is_a?(type)
        raise Emerald::TypeError.new(
          message || "expected #{type} got #{arg.class}",
          env.file,
          env.current_offset,
          env.stack_frames
        )
      end
    end

    module BaseClassMethods
      module ClassMethods
        def to_s
          name.delete_prefix("Emerald::Types::")
        end
      end

      def self.included(base)
        base.extend ClassMethods
      end
    end

    module UserDefinedTypeClassMethods
      module ClassMethods
        def constructable?
          true
        end

        def add_fields(new_fields)
          @fields.concat(new_fields)
          new_fields.each { |field| attr_accessor field.sym }
        end

        def fields
          @fields
        end
      end

      def self.included(base)
        base.extend ClassMethods
        base.instance_eval { @fields = [] }
      end

      def initialize(env, args)
        if args.is_a?(Emerald::Types::Hashmap)
          args.hashmap.each do |field, value|
            self[Emerald::Types::Symbol.new(field)] = value
          end
        elsif args.is_a?(::Array)
          self.class.fields.zip(args).each do |field, value|
            self[field] = value
          end
        end
      end

      def [](env, attr)
        Emerald::Types.assert_type(env, attr, Emerald::Types::Symbol)
        send(attr.sym)
      end

      def []=(field, value)
        send("#{field.sym}=", value)
      end

      def fields
        self.class.fields
      end

      def to_s
        str = self.class.name.delete_prefix("Emerald::Types::")
        if fields.any?
          str << " {"
          str << fields.map { |key| ":#{key} #{self[Emerald::Environment.new, key]}" }.join(", ")
          str << "}"
        end
        str
      end
    end

    class Base
      extend Forwardable
      include BaseClassMethods

      def self.constructable?
        false
      end

      def to_key
        inspect
      end
    end
  end
end
