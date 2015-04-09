class CachedRecord
  class Store
    class Block
      include CachedRecord::Model::Fields

      field :size, :order, :keys, :values

      attr_reader :key

      def initialize(data, key:, order:, size:)
        super(data)
        @key = key
        self.order ||= order
        self.size ||= size
        self.keys ||= []
        self.values ||= []
      end

      def count
        keys.length
      end

      def items
        values
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
            else #we're at the end
              # adds to end of array
              index = -1
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
            else
              index = -1
            end
          end
        end

        keys.insert(index, key)
        values.insert(index, value)
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
