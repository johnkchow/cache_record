require 'dalli'

class CachedRecord
  class StoreAdapter
    class Memcached < StoreAdapter
      adapter :memcached

      def self.client
        config = CachedRecord.config.dalli_config
        @client ||= Dalli::Client.new(config[:host], config)
      end

      attr_reader :client

      def initialize
        @client = self.class.client
      end

      def read(key)
        @client.get(key)
      end

      def read_multi(*keys)
        @client.get_multi(*keys)
      end

      def write(key, value)
        @client.set(key, value)
      end
    end
  end
end
