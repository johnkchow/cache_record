class CachedRecord
  class DataAdapter
    class Collection < DataAdapter
      class << self
        def types(*types)
          @types ||= []
          if types.length > 0
            @types = @types + types.map(&:to_sym)
          end
          @types
        end
      end

      attr_reader :types

      def initialize(types: self.class.types, sort_key: nil)
        @types = types
        @sort_key = sort_key
      end

      def fetch_batch(ids, type)
        fetch_batch_for_type(ids, type, sort_key: @sort_key)
      end

      def fetch_batch_for_type(ids, type, options)
        raise NotImplementedError
      end

      def fetch_meta_keys
        raise NotImplementedError
      end
    end
  end
end
