class CacheRecord
  class Store
    class BlockCollection
      include Util::Assertion

      attr_reader :header, :adapter, :sort_key, :order, :block_size

      def initialize(header_key,
                     adapter:,
                     sort_key:,
                     order:,
                     block_size: CacheRecord.config.block_size)
        @header = get_header(header_key)
        @adapter = adapter
        @sort_key = sort_key.to_sym
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
            start_index + limit < first_block.count
          end
        end
        items.concat(first_block.items[start_index, items_left])
        items_left = limit - (last_index - start_index + 1)
        blocks[1..-1].each do |block|
          assert("items_left still positive", items_left > 0)
          items.concat(block.items[0, items_left])
          items_left -= block.count
        end
        assert("no more pending items left", items_left <= 0)
        items
      end

      protected

      def get_blocks(keys)
        ordered_blocks = Array.new(keys.length)
        unfound_keys = []
        keys_to_index = {}
        keys.each_with_index do |k, i|
          keys_to_index[k] = i

          if block = @block[k]
            ordered_blocks[i] = block
          else
            unfound_keys << k
          end
        end

        raw_blocks = adapter.read(*unfound_keys)

        raw_blocks.each do |key, raw_block|
          block = build_block(raw_block)
          @blocks[key] = block
          ordered_blocks[keys_to_index[key]] = block
        end
        ordered_blocks
      end

      def build_block(raw_block)
        Block.new(raw_block,
                  sort_key: sort_key,
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
          sort_key: sort_key,
          order: order
        }
      end
    end
  end
end
