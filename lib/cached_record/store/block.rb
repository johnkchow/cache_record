class CachedRecord
  class Store
    class Block
      include CachedRecord::Model::Fields

      field :first_key, :last_key, :size, :order

      attr_reader :key

      def initialize(data, key:, order:, size:)
        super(data)
        @key = key
        self.order ||= order
        self.size ||= size
      end

      def count
        attributes[:items].count
      end

      def items
        attributes[:items].map(&:last)
      end

      def insert(key, value)
        index = nil
        attributes[:items].each_with_index do |(k, _v), i|

          if order == :asc
            if i == 0 && key <= k
              index = i
              break
            elsif next_item = attributes[:items][i + 1]
              next_key = next_item.first
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
            elsif next_item = attributes[:items][i + 1]
              next_key = next_item.first
              if k >= key && key >= next_key
                index = i + 1
                break
              end
            else
              index = -1
            end
          end
        end

        attributes[:items].insert(index, [key, value])
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
