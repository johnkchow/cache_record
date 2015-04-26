class CachedRecord
  class ManagedCollection
    attr_reader :store, :mapper, :sort_key

    def initialize(store:, mapper:, sort_key:)
      @store = store
      @mapper = mapper
      @sort_key = sort_key
    end

    def values(offset: 0, limit:)
      items = store.items(offset: offset, limit: limit)
      items.map { |i| mapper.from_raw_data(i) }
    end

    def insert(id, object, name = nil)
      mapped_model = mapper.map_data_object(object, name: name)

      insert_mapped_model(mapped_model)
    end

    def update_or_insert(id, object, name = nil)
      mapped_model = mapper.map_data_object(object, name: name)

      update_mapped_model(mapped_model) || insert_mapped_model(mapped_model)
    end

    def update(id, object, name = nil)
      mapped_model = mapper.map_data_object(object, name: name)

      update_mapped_model(mapped_model)
    end

    def remove(id, name = nil)
      return unless managed_item = find_store_item_by_id_type(id, name)

      # We must capture the value before removing
      value = managed_item.value

      managed_item.remove!

      mapper.from_raw_data(value)
    end

    def find(id, name = nil)
      return unless managed_item = find_store_item_by_id_type(id, name)

      mapper.from_raw_data(managed_item.value)
    end

    protected

    def update_mapped_model(mapped_model)
      return unless managed_item = find_store_item_by_id_type(id, mapped_model.type)
      managed_item.value = mapped_model.to_hash
      managed_item.save!
      mapped_model
    end

    def insert_mapped_model(mapped_model)
      meta_key = model_meta_key(mapped_model)
      key = model_sort_key(mapped_model)

      store.insert(meta_key, key, mapped_model.to_hash)
      mapped_model
    end

    def model_meta_key(mapped_model)
      {
        id: mapped_model.attribute(:id),
        type: mapped_model.type
      }
    end

    def model_sort_key(mapped_model)
      mapped_model.attribute(sort_key)
    end

    # TODO: get the sort key, do binary search
    def find_store_item_by_id_type(id, type = nil)
      type = (type || :default).to_sym

      store.find_by_meta {|meta| meta[:id] == id && meta[:type] == type}
    end
  end
end
