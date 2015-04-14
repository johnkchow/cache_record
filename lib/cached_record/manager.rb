class CachedRecord
  class Manager
    class << self
      def mapper(mapper = nil)
        if mapper
          @mapper = mapper
        else
          @mapper
        end
      end
    end

    def initialize(store: nil, mapper: nil, data_adapter: nil)
    end

    # returns an managed item
    def fetch(id)
      return unless store = get_store_for_key(cache_key(id))

      build_managed_entity(store)
    end

    protected

    def get_store_for_key(key)
      @stores[key] ||= store_class.new(key, store_options)
    end

    def build_managed_entity(store)
      if collection?
        ManagedCollection.new(
          store: store,
          mapper: mapper
        )
      end
    end

    def collection?
      true
    end

    def adapter
    end

    def mapper
      self.class.mapper
    end
  end
end
