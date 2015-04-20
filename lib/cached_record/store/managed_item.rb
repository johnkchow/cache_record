class CachedRecord
  class Store
    class ManagedItem
      attr_reader :store, :block, :index

      def initialize(store:, block:, index:)
        @store = store
        @block = block
        @index = index
      end

      def value
        block.values[index]
      end

      def value=(value)
        block.values[index] = value
      end

      def key
        block.keys[index]
      end

      def save!
        store.persist_block!(block)
      end
    end
  end
end
