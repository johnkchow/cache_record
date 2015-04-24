class CachedRecord
  class Store
    # Acts as a bridge for BlockCollection to fetch data and encapsulating it
    # from the data_adapter and mapper. This allows the BlockCollection
    # to act more low level if needed
    class CollectionFetcher
      attr_reader :data_adapter, :mapper, :sort_key

      def initialize(data_adapter:, mapper:, sort_key:)
        @data_adapter = data_adapter
        @mapper = mapper
        @sort_key = sort_key
      end

      def fetch_meta_keys
        data_adapter.fetch_meta_keys
      end

      def fetch_key_values(meta_keys)
        order = {}
        types = {}
        keys = Array.new(meta_keys.length)
        values = Array.new(meta_keys.length)

        meta_keys.each_with_index do |hash, i|
          id, type = hash.values_at(:id, :type)
          type ||= :default

          order[type] ||= {}
          order[type][id] = i

          types[type] ||= []
          types[type] << id
        end

        types.each do |type, ids|
          data_objects = data_adapter.fetch_batch(ids, type)
          data_objects.each do |data|
            hash = mapper.serialize_data(data, name: "raw_#{type}")

            id = hash[:data].fetch(:id)
            key = hash[:data].fetch(sort_key)

            i = order[type][id]
            keys[i] = key
            values[i] = hash
          end
        end

        [keys, values]
      end
    end
  end
end
