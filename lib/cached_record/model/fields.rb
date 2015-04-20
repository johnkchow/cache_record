class CachedRecord
  module Model
    module Fields
      module ClassMethods
        def fields(*attrs)
          options = {public_reader: true, public_writer: true}

          if attrs.last.is_a?(Hash)
            options.merge(attrs.last)
            attrs = attrs[0..-2]
          end

          raise ArgumentError, "The attributes is empty" if attrs.empty?
          attrs.map(&:to_sym).each do |a|
            if options[:public_reader]
              define_method(a) do
                @attributes[a]
              end
            end

            if options[:public_writer]
              define_method("#{a}=") do |value|
                @attributes[a] = value
              end
            end
          end
        end

        alias :field :fields
      end

      def self.included(base)
        base.extend ClassMethods
      end

      attr_reader :attributes

      def initialize(attributes = nil)
        raise ArgumentError, "Attributes must be a hash" unless attributes
        @attributes = {}

        from_hash(attributes || {})
      end

      def from_hash(attributes)
        attributes.each do |key, value|
          @attributes[key.to_sym] = value
        end
      end

      def to_hash
        attributes.dup
      end
    end
  end
end
