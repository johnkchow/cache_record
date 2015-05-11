require 'spec_helper'
require 'cached_record/store_adapter/memcached'

# QUESTION: How do we want to resolve the missing data?
# Solution one: Inject the data_adapter into BlockCollection, and
# have the BlockCollection resolve it internally


RSpec.describe CachedRecord::Manager do
  before(:all) do
    class TestBlockModel
      include CachedRecord::Model::Fields

      field :id, :prop
    end

    class TestBlockMapper < CachedRecord::Mapper
      model TestBlockModel

      map :data, mapper: :map_data

      def map_data(model, map_data)
        model.from_hash(map_data)
      end
    end

    class TestBlockDataAdapter < CachedRecord::DataAdapter::Collection
      def initialize(*args)
        super

        @data = raw_data.inject({}) do |h, d|
          id = d[:id]
          h[id] = d
          h
        end
      end

      def fetch_meta_keys(id, options)
        @data.keys.sort.map do |d|
          {key: d, meta: d}
        end
      end

      def fetch_batch_for_type(ids, type, options)
        ids.map do |id|
          @data.fetch(id)
        end
      end

      def raw_data
        [
          {id: 1, prop: "one"},
          {id: 2, prop: "two"},
          {id: 3, prop: "three"},
          {id: 4, prop: "four"},
          {id: 5, prop: "five"},
          {id: 6, prop: "six"},
        ]
      end
    end

    class TestEmbeddedBlockManager < CachedRecord::Manager
      storage :embedded,
        sort_key: :prop,
        block_size: 4,
        order: :asc,
        adapter: :memory

      mapper TestBlockMapper
      adapter TestBlockDataAdapter
    end

    class TestEmbeddedBlockManagerWithMemcached < CachedRecord::Manager
      storage :embedded,
        sort_key: :prop,
        block_size: 4,
        order: :asc,
        adapter: :memcached

      mapper TestBlockMapper
      adapter TestBlockDataAdapter
    end
  end

  context "Embedded Block Store" do
    subject do
      TestEmbeddedBlockManager.build
    end

    describe "#fetch" do
      let(:collection_owner_id) { 100 }

      it "should return a ManagedCollection" do
        managed_collection = subject.fetch(collection_owner_id)

        expect(managed_collection).to be_a(CachedRecord::ManagedCollection)
      end
    end
  end

  context "Embedded Block Store with Memcached Adapter" do
    subject do
      TestEmbeddedBlockManagerWithMemcached.build
    end

    describe "#fetch" do
      let(:collection_owner_id) { 100 }

      it "should return a ManagedCollection" do
        managed_collection = subject.fetch(collection_owner_id)

        expect(managed_collection).to be_a(CachedRecord::ManagedCollection)
      end
    end
  end
end
