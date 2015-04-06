class CachedRecord
  class Manager
    def fetch(id)
      key = cache_key(id)

      store = get_store_for_key(key)

      build_managed_entity(store)
    end

    protected

    def get_store_for_key(key)
      @stores[key] ||= store_class.new(key, store_options)
    end

    def build_managed_entity(store)
    end
  end
end
