class CachedRecord
  class StoreAdapter
    class Memory
      def initialize(hash = {})
        @hash = hash
      end

      def read(key)
        @hash[key]
      end

      def read_multi(*keys)
        keys.inject({}) do |hash, key|
          hash[key] = @hash[key]
          hash
        end
      end

      def write(key, value)
        @hash[key] = value
      end
    end
  end
end
