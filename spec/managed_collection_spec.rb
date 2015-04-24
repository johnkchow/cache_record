require 'spec_helper'
require "cached_record/store_adapter/memory"

RSpec.describe CachedRecord::ManagedCollection do
  class ManagedCollectionModel
    attr_accessor :id, :key, :prop

    def initialize(attributes = {})
      from_hash(attributes)
    end

    def to_hash
      {
        id: @id,
        key: @key,
        prop: @prop,
      }
    end

    def from_hash(attributes)
      @id, @key, @prop = attributes.values_at(:id, :key, :prop)
    end
  end

  class ChildManagedCollectionModel < ManagedCollectionModel; end

  class ManagedCollectionRecord
    attr_reader :id, :key

    def initialize(id, key, prop)
      @id = id
      @key = key
      @prop = prop
    end

    def record_prop
      @prop
    end
  end

  class ManagedCollectionMapper < CachedRecord::Mapper
    model ManagedCollectionModel
    model ChildManagedCollectionModel, type: :test_child

    version 1

    map ManagedCollectionRecord, mapper: :map_test_record, type: :test_child

    map :test_record_2, mapper: :map_test_record_2, type: :test_child

    def map_test_record(model, object)
      model.id = object.id
      model.key = object.key
      model.prop = object.record_prop
    end

    def map_test_record_2(model, object)
      model.id = object.id
      model.key = object.key
      model.prop = object.record_prop + "2"
    end
  end

  describe "#insert" do
    let(:keys) { [] }
    let(:values) { [] }

    let(:store_adapter) { CachedRecord::StoreAdapter::Memory.new }
    let(:data_fetcher) { MockDataFetcher.new(keys, values) }
    let(:mapper) { ManagedCollectionMapper.new}

    let(:block_store) do
      CachedRecord::Store::BlockCollection.new(
        "header_key",
        store_adapter: store_adapter,
        data_fetcher: data_fetcher,
        order: :asc,
        block_size: 4,
      )
    end

    let(:sort_key) { :key }

    subject do
      CachedRecord::ManagedCollection.new(
        store: block_store,
        mapper: mapper,
        sort_key: sort_key,
      )
    end

    let(:test_record) { ManagedCollectionRecord.new(1, 15, "double_test") }

    let(:test_records) do
      [15, 2, 4, 19, 1, 10, 17, 11, 20].map do |i|
        ManagedCollectionRecord.new(i, i, "prop-#{i}")
      end
    end

    it "should add to the block store" do
      adding_records = -> {
        test_records.each do |test_record|
          subject.insert(test_record.id, test_record)
        end
      }
      expect(adding_records).to change { block_store.total_count }.from(0).to(test_records.count)
    end
  end
end
