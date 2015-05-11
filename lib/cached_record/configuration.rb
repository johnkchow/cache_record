class CachedRecord
  class Configuration
    attr_accessor :block_size, :dalli_config

    def initialize
      @block_size = 1000

      @dalli_config = {}
    end
  end
end
