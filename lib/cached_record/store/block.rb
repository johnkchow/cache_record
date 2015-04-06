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
    end
  end
end
