class CachedRecord
  class ManagedCollection
    attr_reader :store, :mapper, :sort_key

    def initialize(store:, mapper:, sort_key:)
      @store = store
      @mapper = mapper
      @sort_key = sort_key
    end

    def values(offset:, limit:)
      items = store.items(offset: offset, limit: limit)
      items.map { |i| mapper.build_model(i) }
    end

    def insert(id, object, name = nil)
      mapped_model = mapper.map_data_object(object, name: name)

      if managed_item = find_store_item_by_id_type(id, mapped_model.type)
        managed_item.value = mapped_model.to_hash
        managed_item.save!
      else
        meta_key = model_meta_key(mapped_model)
        key = model_sort_key(mapped_model)

        managed_item = store.insert(meta_key, key, mapped_model.to_hash)
      end
      mapped_model
    end

    def update_model(model)
      # return if the model hasn't been modified
      #
      # check hash to see where the block is loaded
      # get the raw attributes for the model
      # go into the block and update the appropriate item
      #   check block hash to get model index; else build up hash
      #   overwrite the element in array with the new attributes
      # persist the block
      #   serialize all block data
      #   write to key
    end

    def update(id, object, type = nil)
      managed_item = find_store_item_by_id_type(id, type)

      return unless managed_item

      value = managed_item.value

      mapped_model = mapper.map_raw_data(value)

      managed_item.value = mapped_model.to_hash
      managed_item.save!
    end

    def add(id, object, type = nil)
    end

    protected

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
    def find_store_item_by_id_type(id, type)
      store.find_by_meta {|meta| meta[:id] == id && meta[:type] == type}
    end
  end
end
