class MockDataFetcher
  def initialize(keys, values)
    @keys = keys
    @values = values

    @keys_index = {}
    @keys.each_with_index do |k,i|
      @keys_index[k] = i
    end
  end

  def fetch_key_values(meta_keys)
    keys = []
    values = []
    meta_keys.map do |h|
      index = @keys_index[h[:meta]]
      keys << @keys[index]
      values << @values[index]
    end
    [keys, values]
  end

  def fetch_meta_keys
    @keys.map do |k|
      {key: k, meta: k}
    end
  end
end
