class CachedRecord
  class ManagedCollection
    attr_reader :store

    def initialize(store:, mapper:)
      @store = store
      @mapper = mapper
    end

    def values(offset:, limit:)
      # first find the raw blocks that the offset/limit overlap
      #   load header block
      #     fetch from memcache
      #     deserialize data
      #   then iterate through each block meta info to determine if the offset/limit to find the exact block keys
      #   load the blocks into the memory
      #     multi-fetch from memcache
      #     deserialize data
      #   return the blocks
      #
      # for each block
      #   for each underlying value
      #     run the mapper to build up a model
      #     cache the built up model into hash (id => block, model)
      # return the values
      items = store.items(offset: offset, limit: limit)
      items.map { |i| mapper.serialize_model(i) }
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

    def update(id, object, mapper_name = nil)
      managed_item = store.find { |d| d[:id] == id}

      return unless managed_item

      model = mapper.serialize_model(managed_item.value)
      mapper.map(model, object, mapper_name)
      managed_item.value = model.to_hash
      managed_item.save!
      model
    end

    def add(id, object, type = nil)
      # check that the type is valid
      #   if the mapping has multiple types, it should be inthat
      #   if the mapping has single type, it should just be nil
      #
      # Run the mapper to get the model
      # get raw attributes of the model
      # tell the store to update the store with attributes
      #   if the item already exists as duplicate in block, explode
      # tell the store to persist

      #model = mapper.
    end
  end
end
