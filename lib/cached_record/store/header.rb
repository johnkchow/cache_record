class CachedRecord
  class Store
    class Header
      attr_reader :total_count, :meta_blocks, :key, :order

      def initialize(data)
        @key = data[:key]
        @order = data.fetch(:order).to_sym
        @meta_blocks = (data[:blocks] || []).map { |b| MetaBlock.new(b, order) }
      end

      def to_hash
        {
          order: @order,
          blocks: @meta_blocks.map {|b| b.to_hash },
        }
      end

      def total_count
        @meta_blocks.inject(0) { |sum, block| sum + block.count }
      end

      def create_block(block_key:, key:, meta_key:)
        data = {
          key: block_key,
          keys_data: [{key: key, meta: meta_key}]
        }

        new_block = MetaBlock.new(data, order)

        # TODO do binary search instead of linear
        insert_before = nil
        case order
        when :asc
          meta_blocks.each_with_index do |block, i|
            if block.min_key > new_block.max_key
              insert_before = i
              break
            end
          end
        when :desc
          meta_blocks.each_with_index do |block, i|
            if new_block.max_key > block.min_key
              insert_before = i
              break
            end
          end
        end

        # insert at the end
        insert_before ||= -1
        meta_blocks.insert(insert_before, new_block)
      end

      def meta_keys_for_block_key(block_key)
        meta_block = find_meta_block(block_key)
        meta_block.keys_data
      end

      def empty_blocks?
        @meta_blocks.empty?
      end

      def block_count
        @meta_blocks.count
      end

      def split_meta_block(block_key)
        index = meta_blocks.index {|mb| mb.key == block_key }
        meta_block = meta_blocks[index]
        first, last = meta_block.split
        meta_blocks.insert(index, first)
        meta_blocks[index + 1] = last
        [first, last]
      end

      def block_keys_for_offset_limit(offset, limit)
        return nil if offset > total_count

        offset_left = offset
        start_block_index = 0

        while (block = meta_blocks[start_block_index]) && (offset_left - block.count) >= 0
          offset_left -= block.count
          start_block_index += 1
        end

        first_block_offset = offset_left

        last_block_index = start_block_index
        limit_left = limit - (meta_blocks[start_block_index].count - first_block_offset)
        if limit_left > 0
          while (block = meta_blocks[last_block_index]) && limit_left > 0
            limit_left -= block.count
            last_block_index += 1
          end
        end

        block_keys = meta_blocks[start_block_index..last_block_index].map do |b|
          b.key
        end

        [block_keys, first_block_offset]
      end

      protected

      def build_meta_block(block)
        MetaBlock.new(block.meta_hash, order)
      end

      def find_meta_block(block_key)
        meta_blocks.find {|block| block.key == block_key }
      end
    end
  end
end
