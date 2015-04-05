class CacheRecord
  class Store
    class Block
      include CacheRecord::Model::Fields

      field :first_key, :last_key, :size, :sort_key, :order

      attr_reader :key

      def initialize(data, key:, sort_key:, order:, size:)
        super(data)
        @key = key
        self.sort_key ||= sort_key
        self.order ||= order
        self.size ||= size
      end

      def count
        attributes[:items].count
      end

      def items
        attributes[:items].dup
      end
    end
  end
end
