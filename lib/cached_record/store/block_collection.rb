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

        # TODO: instead of concat, let's precalculate the returned
        # size from the meta data in the header block
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
        # if we have no blocks
        #   create new block
        #   insert value into that block
        # else if we find an existing block containing the key
        #   if count < size, return that block
        #   else
        #     generate 2 new blocks with new cache keys
        #     copy halves of the items from the original into the 2 blocks
        #     update the new blocks first_key and last_key
        #     replace the original metablock from header with new blocks info into header
        #     we need to split the block into half
        #     then determine if it lies within the first half block or 2nd half block
        #     update the headers meta block info for existing block
        #     save all 3 together
        # else if we find first block where max_key < key and count < size
        # else we find first block where key < min_key and count < size
        # else we create a new block
        #   if the key is less than min(min_keys)
        #   create new block, insert before all blocks
        #
        #   if the key is > max(min_keys)
        #   insert new block at the end of blocks

        if header.empty_blocks?
          block = create_new_block(key, value)
          persist_block!(block)
        else
          meta_blocks = header.meta_blocks
          if meta_blocks.first.can_insert_before?(key)
            block = create_new_block(key, value)
            persist_block!(block)
          else
            # NOTE: do binary search instead of linear
            meta_blocks.each_with_index do |meta_block, i|
              next_meta_block = meta_blocks[i + 1]

              if meta_block.include_key?(key)
                insert_within_block!(meta_block, key, value)
                break
              elsif !meta_block.full? && (!next_meta_block || next_meta_block.can_insert_before?(key))
                insert_within_block!(meta_block, key, value)
                break
              elsif meta_block.can_insert_between?(key, next_meta_block)
                block = create_new_block(key, value)
                persist_block!(block)
                break
              end
            end
          end
        end
        persist_header!
      end

      # Takes a block that must take in a value and return a boolean value
      def remove
        raise NotImplementedError, "todo"
        # loop through all the meta blocks
        #   fetch the block
        #   loop through all items in the block
        #   if the conditional returns true, remove the item
        #
        # NOTE: should we compact here? This is probably the easiest to do, since
        # compacting is only necessary when removing items, as keys may be unbalanced
        #
        # rebalance keys/items if necessary with surrounding blocks
      end

      def save_block!(block)
        persist_block!(block)
        persist_header!
      end

      protected

      def persist_header!
        adapter.write(header.key, header.to_hash)
      end

      def persist_block!(blocks)
        Array(blocks).each do |block|
          update_meta_block(block)
          adapter.write(block.key, block.to_hash)
        end
      end

      def create_new_block(key, value)
        block = build_block(nil, keys: [key], values: [value])
        header.add_block(block.meta_hash)

        block
      end

      def update_meta_block(block)
        header.update_block(block)
      end

      def insert_within_block!(meta_block, key, value)
        block = get_block(meta_block.key)
        if meta_block.should_resize?
          blocks = split_block(block)
          insert_block = blocks.find {|b| b.key_within_range?(key) }
          insert_block.insert(key, value)

          header.replace(meta_block.key, blocks)

          persist_block!(blocks)
          # TODO: don't delete until we save the header in the future
          @blocks.delete(block.key)
        else
          block.insert(key, value)
          update_meta_block(block)

          persist_block!(block)
        end
      end

      def split_block(block)
        min_key, max_key = build_block_key, build_block_key

        block.split(min_key, max_key)
      end

      def get_block(key)
        get_blocks([key]).first
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
        data = {order: order, size: block_size}.merge(raw_block)
        key ||= build_block_key
        Block.new(key, data)
      end

      def build_block_key
        "#{header.key}:block:#{SecureRandom.uuid}"
      end

      def get_header(key)
        header_data = adapter.read(key) || get_header_attributes
        Header.new(header_data.merge(key: key))
      end

      def get_header_attributes
        {
          order: order
        }
      end
    end
  end
end
