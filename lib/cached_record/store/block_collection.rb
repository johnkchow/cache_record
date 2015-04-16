class CachedRecord
  class Store
    class BlockCollection
      include Util::Assertion

      attr_reader :header, :store_adapter, :order, :block_size, :data_adapter

      def initialize(header_key,
                     store_adapter:,
                     data_adapter:,
                     order:,
                     block_size: CachedRecord.config.block_size)
        @store_adapter = store_adapter
        @data_adapter = data_adapter
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
          update_meta_block_and_persist!(block)
        else
          meta_blocks = header.meta_blocks
          if meta_blocks.first.can_insert_before?(key)
            block = create_new_block(key, value)
            update_meta_block_and_persist!(block)
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
                update_meta_block_and_persist!(block)
                break
              end
            end
          end
        end
        persist_header!
      end

      def find
        found_block = nil
        found_index = nil
        header.meta_blocks.each do |meta_block|
          block = get_block(meta_block.key)
          block.values.each_with_index do |item, i|
            if yield(item)
              found_block = block
              found_index = i
              break
            end
          end
        end

        if found_block
          CachedRecord::Store::ManagedItem.new(
            store: self,
            block: found_block,
            index: found_index,
          )
        end
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
        update_meta_block_and_persist!(block)
        persist_header!
      end

      protected

      def persist_header!
        store_adapter.write(header.key, header.to_hash)
      end

      def update_meta_block_and_persist!(blocks)
        Array(blocks).each do |block|
          update_meta_block(block)
          store_adapter.write(block.key, block.to_hash)
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

          update_meta_block_and_persist!(blocks)
          # TODO: don't delete until we save the header in the future
          @blocks.delete(block.key)
        else
          block.insert(key, value)
          update_meta_block(block)

          update_meta_block_and_persist!(block)
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
          raw_blocks = store_adapter.read_multi(*unfound_keys)

          if raw_blocks.any? {|k,v| v.nil? }
            # clear the blocks
            @blocks = {}
            # fetch all the keys
            # update the header's meta blocks
            # fetch all the data that's needed for the blocks
            # reconstitute the blocks
            # persist the blocks
            # and then return the blocks

            unfound_blocks = raw_blocks.inject([]) do |arr, (k, v)|
              arr << k if v.nil?
              arr
            end

            unfound_blocks.each do |block_key|
              ids = header.get_ids_for_block_key(block_key)
              data = data_adapter.fetch_batch_for_type(ids, nil, nil)
            end
          end
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
        header_data = store_adapter.read(key) || get_header_attributes
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
