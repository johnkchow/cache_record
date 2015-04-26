class CachedRecord
  class Manager
    class << self
      def mapper(mapper)
        @mapper = mapper
      end

      def storage(type, options)
        @store_options = options.merge(type: type)
      end

      def adapter(adapter)
        if adapter
          @data_adapter = adapter
        end
        @data_adapter
      end

      def build
        self.new(
          store_options: @store_options,
          mapper: CachedRecord::Factory.build_mapper(@mapper),
          data_adapter: CachedRecord::Factory.build_data_adapter(@data_adapter, @store_options[:sort_key]),
        )
      end

      protected
    end

    def initialize(store_options:, mapper:, data_adapter:)
      @store_options = store_options
      @mapper = mapper
      @data_adapter = data_adapter
    end

    # returns an managed item
    def fetch(id)
      build_managed_entity(id)
    end

    protected

    attr_reader :mapper, :data_adapter, :store

    def cache_key(id)
      "CachedRecord:#{self.class.name}:#{id}"
    end

    def build_managed_entity(id)
      # TODO put this either in registry or factory
      CachedRecord::ManagedCollection.new(
        store: build_store(id),
        mapper: mapper,
        sort_key: sort_key,
      )
    end

    def sort_key
      @store_options.fetch(:sort_key)
    end

    def build_store(id)
      options = @store_options.merge(
        id: id,
        cache_key: cache_key(id),
        mapper: @mapper,
        data_adapter: @data_adapter,
      )

      CachedRecord::Factory.build_store(options)
    end
  end
end
