class CachedRecord
  class Store
    class DataFetcher
      attr_reader :data_adapter, :mapper

      def initialize(data_adapter:, mapper:)
        @data_adapter = data_adapter
        @mapper = mapper
      end

      def fetch_batch_key_values(meta_keys)
        order = {}
        types = {}
        keys = Array.new(meta_keys.length)
        values = Array.new(meta_keys.length)

        meta_keys.each_with_index do |hash, i|
          id, type = hash.values_at(:id, :type)
          type ||= :default

          order[[id, type]] = i
          types[type] ||= []
          types[type] << id
        end

        types.each do |type, ids|
          data_rows = data_adapter.fetch_batch(ids, type)
          data_rows.each do |data|
            hash = mapper.normalize_data(data)
            i = order[[hash[:id], type]]
            keys[i] = hash[:key]
            values[i] = hash[:value]
          end
        end

        [keys, values]
      end
    end
  end
end
