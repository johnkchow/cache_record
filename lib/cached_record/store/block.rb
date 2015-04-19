class CachedRecord
  class Store
    class Block
      include CachedRecord::Model::Fields
      include CachedRecord::Store::SplitArray

      field :size, :order, :keys, :values

      attr_reader :key

      def initialize(key, data)
        super(data)
        @key = key
        self.keys ||= []
        self.values ||= []
      end

      def count
        keys.length
      end

      def min_key
        keys.first
      end

      def max_key
        keys.last
      end

      def meta_hash
        {
          key: key,
          size: size,
          order: order,
          min_key: keys.first,
          max_key: keys.last,
          count: keys.length
        }
      end

      def split(min_block_key, max_block_key)
        first_keys, last_keys = split_array(keys)

        first_values, last_values = split_array(values)

        [
          self.class.new(
            min_block_key,
            keys: first_keys,
            values: first_values,
            order: order,
            size: size,
          ),
          self.class.new(
            max_block_key,
            keys: last_keys,
            values: last_values,
            order: order,
            size: size,
          )
        ]
      end

      def insert(key, value)
        index = nil
        keys.each_with_index do |(k, _v), i|
          if order == :asc
            if i == 0 && key <= k
              index = i
              break
            elsif next_key = keys[i + 1]
              if k <= key && key <= next_key
                index = i + 1
                break
              end
            end
          else
            if i == 0 && key >= k
              index = i
              break
            elsif next_key = keys[i + 1]
              if k >= key && key >= next_key
                index = i + 1
                break
              end
            end
          end
        end

        index ||= -1

        keys.insert(index, key)
        values.insert(index, value)

        index
      end

      def key_within_range?(key)
        case order
        when :asc
          min_key <= key && key <= max_key
        when :desc
          max_key <= key && key <= min_key
        else
          raise ArgumentError, "Unknown order #{order}"
        end
      end

      protected


        # problem: what's the most optimal block reading/writing if it's read heavy
        # items, insert
        #
        # items: backed an array. read: O(M) where M is limit
        # insert: O(2N), scan through array to find index, then shifting elements which is another N ops
        #
        # backed by binary tree
        # items: O(N+M) we have to scan entire tree to get ordered list
        # insert: O(N + log(N))
        #
        #
        # if items are always ordered asc
        #
        # insert:
        #   when asc scan for first index where < key and next el will be > key
        #   do an insert after that first index
        #
        #   when desc
        #     scan for first index BACKWARDS
    end
  end
end
