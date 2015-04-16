class CachedRecord
  class Store
    class Header
      class MetaBlock
        include CachedRecord::Model::Fields

        field :key, :size, :keys_data

        attr_reader :order

        def initialize(data, order)
          super(data)
          @order = order
          raise ArgumentError, "Unknown order #{order}" unless [:desc, :asc].include?(order)
        end

        def full?
          count == size
        end

        def include_key?(key)
          case order
          when :asc
            (min_key <= key && key <= max_key)
          when :desc
            (min_key >= key && key >= max_key)
          end
        end

        def min_key
          if data = keys_data.first
            data[:key]
          end
        end

        def max_key
          if data = keys_data.last
            data[:key]
          end
        end

        def count
          keys_data.length
        end

        def can_insert_or_split?(key)
          # NOTE: the !full? conditional is dependent that no key block ranges overlap
          # and the only block with available slots is the only block with available
          # slots. Otherwise, we may run into key overlapping issues, which will mess
          # with ordering/fetching.
          include_key?(key) || !full?
        end

        def can_insert_before?(key)
          return false if full?

          case order
          when :asc
            key < min_key
          when :desc
            key > min_key
          end
        end

        def can_insert_between?(key, other_block)
          return false unless self.full? && other_block.full?

          block1, block2 = sort_blocks(self, other_block)

          case order
          when :asc
            block1.max_key < key && key < block2.min_key
          when :desc
            block1.max_key > key && key > block2.min_key
          end
        end

        def should_resize?
          count >= size
        end

        protected

        def sort_blocks(block1, block2)
          blocks = if block1.max_key <= block2.max_key && block1.min_key <= block2.min_key
                     [block1, block2]
                   else
                     [block2, block1]
                   end
          blocks.reverse! if order == :desc
          blocks
        end
      end

      attr_reader :total_count, :meta_blocks, :key, :order

      def initialize(data)
        @key = data[:key]
        @order = data.fetch(:order).to_sym
        @meta_blocks = (data[:blocks] || []).map { |b| MetaBlock.new(b, order) }
      end

      def to_hash
        {
          blocks: @meta_blocks.map {|b| b.to_hash },
          order: @order,
        }
      end

      def total_count
        @meta_blocks.inject(0) { |sum, block| sum + block.count }
      end

      def add_block(data)
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

      def empty_blocks?
        @meta_blocks.empty?
      end

      def block_count
        @meta_blocks.count
      end

      def update_block(block)
        meta_block = meta_blocks.find { |b| b.key == block.key }
        meta_block.min_key = block.min_key
        meta_block.max_key = block.max_key
        meta_block.count = block.count
        meta_block.size = block.size
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
        limit_left = limit - (meta_blocks[start_block_index].count - first_block_offset + 1)
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

      # NOTE: Possible critical section
      def replace(original_block_key, new_blocks)
        copy_blocks = Array.new(@meta_blocks.count - 1 + new_blocks.count)
        copy_index = 0
        @meta_blocks.each do |meta_block|
          if meta_block.key == original_block_key
            new_blocks.each_with_index do |block, i|
              copy_blocks[copy_index + i] = build_meta_block(block)
            end
            copy_index += new_blocks.count - 1
          else
            copy_blocks[copy_index] = meta_block
          end
          copy_index += 1
        end

        @meta_blocks = copy_blocks
      end

      protected

      def build_meta_block(block)
        MetaBlock.new(block.meta_hash, order)
      end
    end
  end
end
