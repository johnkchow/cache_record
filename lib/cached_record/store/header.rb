class CacheRecord
  class Store
    class Header
      class MetaBlock
        include CacheRecord::Model::Fields

        field :key, :first_key, :last_key, :count, :size
      end

      attr_reader :total_count

      def initialize(data)
        @sort_key = data.fetch(:sort_key)
        @order = data.fetch(:order)
        @meta_blocks = (data[:blocks] || []).map {|b| MetaBlock.new(b)}
        @total_count = data[:total_count] || 0
      end

      def to_hash
        {
          blocks: @meta_blocks.map(&:to_hash),
          total_count: @total_count,
          sort_key: @sort_key,
          order: @order,
        }
      end

      def block_keys_for_offset_limit(offset, limit)
        return nil if offset > total_count

        offset_left = offset
        start_block_index = 0

        while (block = @meta_blocks[start_block_index]) && (offset_left - block.count) >= 0
          offset_left -= block.count
          start_block_index += 1
        end

        first_block_offset = offset_left

        last_block_index = start_block_index
        limit_left = limit - (@meta_blocks[start_block_index].count - first_block_offset + 1)
        if limit_left > 0
          while (block = @meta_blocks[last_block_index]) && limit_left > 0
            limit_left -= block.count
            last_block_index += 1
          end
        end

        block_keys = @meta_blocks[start_block_index..last_block_index].map do |b|
          b.key
        end

        [block_keys, first_block_offset]
      end
    end
  end
end
