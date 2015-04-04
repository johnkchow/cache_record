class CacheRecord
  class ManagedCollection
    attr_reader :store

    def initialize(store:)
      @store = store
    end

    def values(offset: self.offset, limit: self.limit)
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

    def add(id, value, type = nil)
      # check that the type is valid
      #   if the mapping has multiple types, it should be inthat
      #   if the mapping has single type, it should just be nil
      #
      # Run the mapper to get the model
      # get raw attributes of the model
      # tell the store to update the store with attributes
      #   if the item already exists as duplicate in block, explode
      # tell the store to persist
    end
  end
end
