class CachedRecord
  class Store
    class ManagedItem
      attr_reader :store, :block, :meta_block, :index

      def initialize(store:, block:, meta_block:, index:)
        @store = store
        @block = block
        @index = index
        @meta_block = meta_block
      end

      def removed?
        !!@removed
      end

      def value
        raise RemovedError if removed?

        block.values[index]
      end

      def key
        raise RemovedError if removed?

        block.keys[index]
      end

      def set_meta_key_and_value(meta_key, value)
        raise RemovedError if removed?

        meta_block.keys_data[index] = meta_key
        block.values[index] = value
      end

      def remove!
        raise RemovedError if removed?


        block.delete_at(index)
        meta_block.delete_at(index)

        save!

        @removed = true
      end

      def save!
        raise RemovedError if removed?

        store.persist_block!(block)
        store.persist_header!
      end
    end
  end
end
