class CacheRecord::Store::Collection
  attr_reader :key

  def initialize(key, options = {})
    @key = key
  end
end
