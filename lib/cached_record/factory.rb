class CachedRecord
  module Factory
    class << self
      def build_store(id:,
                      cache_key:,
                      type:,
                      sort_key:,
                      mapper:,
                      adapter:,
                      data_adapter:,
                      order: :asc,
                      block_size: CachedRecord.config.block_size)

        data_fetcher = data_fetcher_class(type).new(
          id: id,
          data_adapter: build_data_adapter(data_adapter, sort_key),
          mapper: build_mapper(mapper),
          sort_key: sort_key
        )

        store_class(type).new(
          cache_key,
          store_adapter: build_store_adapter(adapter),
          data_fetcher: data_fetcher,
          order: order,
          block_size: block_size
         )
      end

      def build_data_adapter(adapter, sort_key)
        if adapter.is_a?(Class)
          adapter.new(sort_key: sort_key)
        else
          adapter
        end
      end

      def build_store_adapter(adapter)
        if adapter.is_a?(Class)
          adapter.new
        elsif adapter.is_a?(Symbol)
          CachedRecord::StoreAdapter.registered_adapters.fetch(adapter).new
        else
          adapter
        end
      end

      def build_mapper(mapper)
        if mapper.is_a?(Class)
          mapper.new
        else
          mapper
        end
      end

      protected

      def data_fetcher_class(type)
        case type
        when :embedded
          CachedRecord::Store::CollectionFetcher
        end
      end

      def store_class(type)
        case type
        when :embedded
          CachedRecord::Store::BlockCollection
        else
          raise FactoryError
        end
      end
    end
  end
end
