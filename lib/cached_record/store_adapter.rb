class CachedRecord
  class StoreAdapter
    @@adapters = {}

    class << self
      def adapter(adapter)
        @@adapters[adapter] = self
      end

      def registered_adapters
        @@adapters
      end
    end

    def read(key)
      raise NotImplementedError
    end

    def read_multi(*keys)
      raise NotImplementedError
    end

    def write(key, value)
      raise NotImplementedError
    end
  end
end
