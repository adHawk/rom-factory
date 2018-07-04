module ROM::Factory
  module Attributes
    # @api private
    module Association
      def self.new(assoc, builder, *traits, **options)
        const_get(assoc.definition.type).new(assoc, builder, *traits, **options)
      end

      # @api private
      class Core
        attr_reader :assoc, :options, :traits

        # @api private
        def initialize(assoc, builder, *traits, **options)
          @assoc = assoc
          @builder_proc = builder
          @traits = traits
          @options = options
        end

        # @api private
        def builder
          @__builder__ ||= @builder_proc.call
        end

        # @api private
        def name
          assoc.key
        end

        # @api private
        def dependency?(*)
          false
        end

        # @api private
        def value?
          false
        end
      end

      # @api private
      class ManyToOne < Core
        # @api private
        def call(attrs = EMPTY_HASH)
          if attrs.key?(name) && !attrs[foreign_key]
            assoc.associate(attrs, attrs[name])
          elsif !attrs[foreign_key]
            struct = builder.persistable.create(*traits)
            tuple = { name => struct }
            assoc.associate(tuple, struct)
          end
        end

        # @api private
        def foreign_key
          assoc.foreign_key
        end
      end

      # @api private
      class OneToMany < Core
        # @api private
        def call(attrs = EMPTY_HASH, parent)
          return if attrs.key?(name)

          structs = count.times.map do
            builder.persistable.create(*traits, assoc.associate(attrs, parent))
          end

          { name => structs }
        end

        # @api private
        def dependency?(rel)
          assoc.source == rel
        end

        # @api private
        def count
          options.fetch(:count)
        end
      end

      # @api private
      class OneToOne < OneToMany
        # @api private
        def call(attrs = EMPTY_HASH, parent)
          return if attrs.key?(name)

          struct = builder.persistable.create(*traits, assoc.associate(attrs, parent))

          { name => struct }
        end
      end
    end
  end
end
