class CachedRecord
  class Store
    class BlockCollection
      include Util::Assertion

      attr_reader :header, :adapter, :order, :block_size

      def initialize(header_key,
                     adapter:,
                     order:,
                     block_size: CachedRecord.config.block_size)
        @adapter = adapter
        @header = get_header(header_key)
        @block_size = block_size
        @order = order.to_sym
        @blocks = {}
      end

      def items(offset:, limit:)
        block_keys, start_index = header.block_keys_for_offset_limit(offset, limit)
        blocks = get_blocks(block_keys)

        items = []
        items_left = limit
        first_block = blocks.first
        if blocks.length == 1
          assert("single block contains all items requested") do
            start_index + limit <= first_block.count
          end
        end
        items.concat(first_block.items[start_index, items_left])
        items_left = limit - (first_block.count - start_index)
        blocks[1..-1].each do |block|
          assert("items_left still positive", items_left > 0)
          items.concat(block.items[0, items_left])
          items_left -= block.count
        end
        assert("no more pending items left", items_left <= 0)
        items
      end

      def insert(key, value)
        if block_key = header.find_block_key(key)
          block = get_block(block_key)

          # call block.insert(item)
          #   it does a binary search for the index where it'd be inserted
          #   then it inserts the item
          #   then it

          # if split block
          #   generate 2 new blocks with new cache keys
          #   copy halves of the items from the original into the 2 blocks
          #   update the new blocks first_key and last_key
          #   replace the original metablock from header with new blocks info into header
          #   update the headers meta block info for existing block
          #   save all 3 together
        else
          # generate new block with new cache key
          # insert
        end
      end

      protected

      def get_block(key)
        get_blocks(key).first
      end

      def get_blocks(keys)
        ordered_blocks = Array.new(keys.length)
        unfound_keys = []
        keys_to_index = {}

        keys.each_with_index do |k, i|
          keys_to_index[k] = i

          if block = @blocks[k]
            ordered_blocks[i] = block
          else
            unfound_keys << k
          end
        end

        if unfound_keys.any?
          raw_blocks = adapter.read_multi(*unfound_keys)

          raw_blocks.each do |key, raw_block|
            block = build_block(key, raw_block)
            @blocks[key] = block
            ordered_blocks[keys_to_index[key]] = block
          end
        end
        ordered_blocks
      end

      def build_block(key, raw_block)
        Block.new(raw_block,
                  key: key,
                  order: order,
                  size: block_size
                 )
      end

      def get_header(key)
        header_data = adapter.read(key) || get_header_attributes
        Header.new(header_data)
      end

      def get_header_attributes
        {
          order: order
        }
      end
    end
  end
end
