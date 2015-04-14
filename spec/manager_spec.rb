require 'spec_helper'

class HashObject
  def initialize(hash)
    @hash = hash
  end

  def [](value)
    @hash[value]
  end

  def []=(key, value)
    @hash[key] = value
  end

  def to_hash
    @hash
  end

  def method_missing(*args)
    case args.length
    when 1
      @hash[args.first.to_sym]
    when 2
      @hash[args.first.to_sym] = args.last
    when 3
      super
    end
  end
end

class TestBlockMapper
  def serialize_model(raw_data)
    HashObject.new(raw_data)
  end

  def map(model, object, name = nil)
    model[:_set_] = true
  end
end

class TestBlockDataAdapter
end

class TestBlockManager < CachedRecord::Manager
  storage :embedded,
    sort_by: :id,
    order: :asc

  mapper TestBlockMapper
  adapter TestBlockDataAdapter
end

# QUESTION: How do we want to resolve the missing data?
# Solution one: Inject the data_adapter into BlockCollection, and
# have the BlockCollection resolve it internally


RSpec.describe CachedRecord::Manager do
  context "Block Collection" do
  end
end
