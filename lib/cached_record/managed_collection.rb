class CachedRecord
  class ManagedCollection
    attr_reader :store

    def initialize(store:, mapper:)
      @store = store
      @mapper = mapper
    end

    def values(offset:, limit:)
      items = store.items(offset: offset, limit: limit)
      items.map { |i| mapper.build_model(i) }
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
      managed_item = store.find_by_meta {|meta| meta[:id] == id && meta[:type] == type}

      return unless managed_item

      value = managed_item.value

      mapped_model = mapper.map_raw_data(value)

      managed_item.value = mapped_model.to_hash
      managed_item.save!
      model
    end

    def add(id, object, type = nil)
    end
  end
end
