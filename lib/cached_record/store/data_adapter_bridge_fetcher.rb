class CachedRecord
  class Store
    class DataAdapterBridgeFetcher

      def initialize(id:, data_adapter:, mapper:, sort_key:)
        @id = id
        @data_adapter = data_adapter
        @mapper = mapper
        @sort_key = sort_key
      end

      def fetch_meta_keys
        data_adapter.fetch_meta_keys(id, sort_key: sort_key)
      end

      def fetch_key_values(meta_keys)
        order = {}
        types = {}
        keys = Array.new(meta_keys.length)
        values = Array.new(meta_keys.length)

        meta_keys.each_with_index do |hash, i|
          meta_key = hash[:meta]
          if meta_key.is_a?(Hash)
            id, type = meta_key.values_at(:id, :type)
          else
            id = meta_key
          end
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

      protected

      attr_reader :id, :data_adapter, :mapper, :sort_key
    end
  end
end
