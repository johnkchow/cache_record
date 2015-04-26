require 'spec_helper'
require 'cached_record/store_adapter/memory'
require 'awesome_print'

RSpec.describe CachedRecord::Store::BlockCollection do
  subject do
    options = {
      data_fetcher: mock_data_fetcher,
      store_adapter: mock_store_adapter,
      order: order,
      block_size: 100
    }
    described_class.new(header_key, options)
  end

  let(:header_key) { "header" }
  let(:block_data) { {} }
  let(:missing_block_data) { {} }
  let(:fetcher_keys) { missing_block_data.map {|k,v| v[:keys] }.flatten }
  let(:fetcher_values) { missing_block_data.map {|k,v| v[:values] }.flatten }

  let(:mock_data_fetcher) { MockDataFetcher.new(fetcher_keys, fetcher_values) }
  let(:mock_store_adapter) do
    filtered_block_data = block_data.select { |k,v| v[:keys] }
    CachedRecord::StoreAdapter::Memory.new(filtered_block_data.merge(header_key => header_data))
  end

  let(:header_data) do
    all_block_data = block_data.merge(missing_block_data)

    blocks = all_block_data.keys.sort.inject([]) do |array, key|
      array << build_meta_block(key, all_block_data[key])
      array
    end

    total_count = block_data.inject(0) {|c,(_,b)| c + (b[:count] || b[:keys].length) }
    {
      total_count: total_count,
      blocks: blocks,
      order: order.to_s,
    }
  end

  shared_context "simple asc order" do
    let(:order) { :asc }
    let(:block_data) do
      {
        "block1" => {
          order: :asc,
          size: 20,
          keys: [1,2,3,4],
          values: [1,2,3,4],
        },
        "block2" => {
          order: :asc,
          size: 20,
          keys: [5,6,7,8],
          values: [5,6,7,8],
        },
        "block3" => {
          order: :asc,
          size: 20,
          keys: [9,10,11,12],
          values: [9,10,11,12],
        },
      }
    end
  end

  shared_context "simple desc order" do
    let(:order) { :desc }
    let(:block_data) do
      {
        "block1" => {
          order: :desc,
          size: 20,
          keys: [12, 11, 10, 9],
          values: [12, 11, 10, 9],
        },
        "block2" => {
          order: :desc,
          size: 20,
          keys: [8, 7, 6, 5],
          values: [8, 7, 6, 5],
        },
        "block3" => {
          order: :desc,
          size: 20,
          keys: [4, 3, 2, 1],
          values: [4, 3, 2, 1],
        },
      }
    end
  end

  shared_context "complex asc order" do
    let(:order) { :asc }

    let(:block_data) do
      {
        "block1" => {
          size: 4,
          order: :asc,
          keys: [1,2,3,4],
          values: [1,2,3,4],
        },
        "block2" => {
          size: 4,
          order: :asc,
          keys: [8,9,12],
          values: [8,9,12],
        },
        "block3" => {
          size: 4,
          order: :asc,
          keys: [16],
          values: [16],
        }
      }
    end
  end

  shared_context "complex desc order" do
    let(:order) { :desc }

    let(:block_data) do
      {
        "block1" => {
          size: 4,
          order: :desc,
          keys: [16, 16, 16, 16],
          values: [16, 16, 16, 16],
        },
        "block2" => {
          size: 4,
          order: :desc,
          keys: [12,9,8],
          values: [12,9,8],
        },
        "block3" => {
          size: 4,
          order: :desc,
          keys: [4],
          values: [4],
        },
      }
    end
  end

  shared_context "asc order with missing block" do
    let(:order) { :asc }

    let(:block_data) do
      {
        "block1" => {
          size: 4,
          order: :asc,
          keys: [1,2,3,4],
          values: [1,2,3,4],
        },
        "block3" => {
          size: 4,
          order: :asc,
          keys: [16],
          values: [16],
        }
      }
    end

    let(:missing_block_data) do
      {
        "block2" => {
          size: 4,
          order: :asc,
          keys: [8,9,12],
          values: [8,9,12],
        }
      }
    end
  end

  describe "#initialize" do
    context "when the header is nil" do
      let(:header_data) { nil }
      let(:order) { :asc }
      let(:fetcher_keys) { (1..12).to_a }
      let(:fetcher_values) { (1..12).to_a }

      it "should regenerate the header" do
        header = subject.header
        expect(header.total_count).to eq(12)
      end
    end
  end

  describe "#items" do

    context "when header isn't in cache" do
      let(:order) { :asc }
      let(:header_data) { nil }
      let(:fetcher_keys) { (1..12).to_a }
      let(:fetcher_values) { (1..12).to_a }

      context "offset 2, limit 4" do
        it "should return [3,4,5,6]" do
          expect(subject.items(offset: 2, limit: 4)).to eq([3,4,5,6])
        end
      end
    end

    context "when order is asc" do
      include_context "simple asc order"

      context "offset 2, limit 4" do
        it "should return [3,4,5,6]" do
          expect(subject.items(offset: 2, limit: 4)).to eq([3,4,5,6])
        end
      end

      context "offset 1, limit 3" do
        it "should return [2,3,4] " do
          expect(subject.items(offset: 1, limit: 3)).to eq([2,3,4])
        end
      end
    end

    context "when order is desc" do
      include_context "simple desc order"

      context "offset 2, limit 4" do
        it "should return [3,4,5,6]" do
          expect(subject.items(offset: 2, limit: 4)).to eq([10,9,8,7])
        end
      end

      context "offset 1, limit 3" do
        it "should return [2,3,4] " do
          expect(subject.items(offset: 1, limit: 3)).to eq([11,10,9])
        end
      end
    end

    context "when order is asc and a block is missing" do
      include_context "asc order with missing block"
      it "should fetch the data from the adapter and return the items" do
        expect(subject.items(offset: 4, limit: 4)).to eq([8,9,12,16])
      end
    end
  end

  describe "#insert" do
    context "when order is asc" do
      let(:order) { :asc }

      context "empty collection" do
        it "should persist a single block of key" do
          subject.insert(1, 1, 1)
          header = fetch_header(header_key)

          expect(header.block_count).to eq 1

          block = fetch_blocks_from_header(header).first

          expect(block.min_key).to eq(1)
          expect(block.max_key).to eq(1)
          expect(block.count).to eq(1)
          expect(block.values).to eq([1])
        end

        context "inserting multiple values that should create a new block" do
          let(:inserting_values) do
            [15, 2, 4, 19, 1, 19, 10, 17, 11, 20].map(&:to_s)
          end

          it "should correctly increase count" do
            inserting_values.each do |i|
              subject.insert(i, i, i)
            end

            expect(subject.total_count).to eq(inserting_values.count)
          end

          it "should create multiple blocks to fit all values" do
            inserting_values.shuffle.each do |i|
              subject.insert(i, i, i)
            end
          end

          it "should return the values" do
            inserting_values.shuffle.each do |i|
              subject.insert(i, i, i)
            end

            expect(subject.items(offset: 0, limit: inserting_values.count)).to eq(inserting_values.sort)
          end
        end
      end

      context "non empty collection" do
        include_context "complex asc order"

        context "when inserting key/value into middle block with available slots" do
          it "shouldn't create anymore blocks" do
            expect { subject.insert(10, 10, 10) }.to_not change { fetch_header(header_key).block_count }
          end
          it "should persist the block with the inserted middle" do
            subject.insert(10, 10, 10)
            block2 = fetch_blocks("block2").first
            expect(block2.values).to eq ([8,9,10,12])
          end

          it "should increment the meta block count" do
            meta_block = nil
            expect { subject.insert(10, 10, 10) }.to change {
              header = fetch_header(header_key)
              meta_block = header.meta_blocks.find {|b| b.key == "block2" }
              meta_block.count
            }.from(3).to(4)

            expect(meta_block.min_key).to eq(8)
            expect(meta_block.max_key).to eq(12)
          end

          it "shouldn't change the min_key" do
            expect { subject.insert(10, 10, 10) }.to_not change {
              header = fetch_header(header_key)
              meta_block = header.meta_blocks.find {|b| b.key == "block2" }
              meta_block.min_key
            }
          end

          it "shouldn't change the max_key" do
            expect { subject.insert(10, 10, 10) }.to_not change {
              header = fetch_header(header_key)
              meta_block = header.meta_blocks.find {|b| b.key == "block2" }
              meta_block.max_key
            }
          end
        end

        context "when inserting key/value into end of middle block w/ available slots" do
          it "shouldn't create anymore blocks" do
            expect { subject.insert(13, 13, 13) }.to_not change { fetch_header(header_key).block_count }
          end
          it "should persist block with correct order" do
            subject.insert(13, 13,13)
            block_values = block_values(header_key)
            expect(block_values).to eq([[1,2,3,4],[8,9,12,13],[16]])
          end

          it "shouldn't change the min_key" do
            expect { subject.insert(13, 13, 13) }.to_not change {
              header = fetch_header(header_key)
              meta_block = header.meta_blocks.find {|b| b.key == "block2" }
              meta_block.min_key
            }
          end

          it "should update the meta block's max key" do
            meta_block = nil
            expect { subject.insert(13, 13, 13) }.to change {
              header = fetch_header(header_key)
              meta_block = header.meta_blocks.find {|b| b.key == "block2" }
              meta_block.max_key
            }.from(12).to(13)
          end
        end

        context "when inserting key/value into beginning of block w/ available slots" do
          it "shouldn't create anymore blocks" do
            expect { subject.insert(7, 7, 7) }.to_not change { fetch_header(header_key).block_count }
          end
          it "should persist block with correct order" do
            subject.insert(7, 7,7)
            block_values = block_values(header_key)
            expect(block_values).to eq([[1,2,3,4],[7,8,9,12],[16]])
          end

          it "should update the meta block's min key" do
            meta_block = nil
            expect { subject.insert(7, 7, 7) }.to change {
              header = fetch_header(header_key)
              meta_block = header.meta_blocks.find {|b| b.key == "block2" }
              meta_block.min_key
            }.from(8).to(7)
          end

          it "shouldn't change the max_key" do
            expect { subject.insert(7, 7, 7) }.to_not change {
              header = fetch_header(header_key)
              meta_block = header.meta_blocks.find {|b| b.key == "block2" }
              meta_block.max_key
            }
          end
        end

        context "when inserting key/value into block that's full" do
          it "should create one more block" do
            expect { subject.insert(2, 2, :new) }.to change { fetch_header(header_key).block_count }.by(1)
          end

          it "should insert the key/value into correct block" do
            subject.insert(2, 2, :new)
            block_values = block_values(header_key)
            expect(block_values).to eq([[1,:new, 2],[3,4],[8,9,12],[16]])
          end
        end

        context "when inserting a key/value that lies between 2 block key-ranges" do
          before do
            subject.insert(7, 7,7)
          end

          it "should create a new block" do
            expect { subject.insert(5, 5, 5) }.to change { fetch_header(header_key).block_count }.by(1)
          end

          it "should insert the key/value into correct block" do
            subject.insert(5, 5, 5)
            block_values = block_values(header_key)
            expect(block_values).to eq([[1,2,3,4],[5],[7,8,9,12],[16]])
          end
        end
      end
    end

    context "when order is desc" do
      let(:order) { :desc }

      context "empty collection" do
        it "should persist a single block of key" do
          subject.insert(1, 1, 1)
          header = fetch_header(header_key)

          expect(header.block_count).to eq 1

          block = fetch_blocks_from_header(header).first

          expect(block.min_key).to eq(1)
          expect(block.max_key).to eq(1)
          expect(block.count).to eq(1)
          expect(block.values).to eq([1])
        end
      end

      context "non empty collection" do
        include_context "complex desc order"

        context "when inserting key/value into middle block with available slots" do
          it "shouldn't create anymore blocks" do
            expect { subject.insert(10, 10, 10) }.to_not change { fetch_header(header_key).block_count }
          end
          it "should persist the block with the inserted middle" do
            subject.insert(10, 10, 10)
            block2 = fetch_blocks("block2").first
            expect(block2.values).to eq ([12,10,9,8])
          end
        end

        context "when inserting key/value into beginning of middle block w/ available slots" do
          it "shouldn't create anymore blocks" do
            expect { subject.insert(13, 13, 13) }.to_not change { fetch_header(header_key).block_count }
          end
          it "should persist block with correct order" do
            subject.insert(13, 13,13)
            block_values = block_values(header_key)
            expect(block_values).to eq([[16,16,16,16],[13,12,9,8],[4]])
          end
        end

        context "when inserting key/value into end of middle block w/ available slots" do
          it "shouldn't create anymore blocks" do
            expect { subject.insert(7, 7, 7) }.to_not change { fetch_header(header_key).block_count }
          end
          it "should persist block with correct order" do
            subject.insert(7,7,7)
            block_values = block_values(header_key)
            expect(block_values).to eq([[16,16,16,16],[12,9,8,7],[4]])
          end
        end

        context "when inserting key/value into block that's full" do
          it "should create one more block via splitting" do
            expect { subject.insert(16, 16, :new) }.to change { fetch_header(header_key).block_count }.by(1)
          end

          it "should insert the key/value into correct block" do
            subject.insert(16, 16, :new)
            block_values = block_values(header_key)
            expect(block_values).to eq([[:new, 16,16],[16,16],[12,9,8],[4]])
          end
        end

        context "when inserting a key/value that lies between 2 block key-ranges" do
          before do
            subject.insert(7,7,7)
          end

          it "should create a new block" do
            expect { subject.insert(15, 15, 15) }.to change { fetch_header(header_key).block_count }.by(1)
          end

          it "should insert the key/value into correct block" do
            subject.insert(15, 15, 15)
            block_values = block_values(header_key)
            expect(block_values).to eq([[16,16,16,16],[15],[12,9,8,7],[4]])
          end
        end
      end
    end
  end

  describe "#find_by_meta" do
    context "simple asc order" do
      include_context "simple asc order"

      context "find block actually finds an item" do
        it "should return managed object" do
          managed_object = subject.find_by_meta { |meta| meta == 12 }
          expect(managed_object.key).to eq(12)
          expect(managed_object.value).to eq(12)
        end
      end

      context "find block doesn't find an item" do
        it "should return nil" do
          expect(subject.find_by_meta {|meta| meta == -1 }).to be_nil
        end
      end
    end

    context "simple desc order" do
      include_context "simple desc order"

      context "find block actually finds an item" do
        it "should return managed object" do
          managed_object = subject.find_by_meta { |v| v == 5 }
          expect(managed_object.key).to eq(5)
          expect(managed_object.value).to eq(5)
        end
      end

      context "find block doesn't find an item" do
        it "should return nil" do
          expect(subject.find_by_meta {|v| v == -1 }).to be_nil
        end
      end
    end
  end

  describe "#remove" do
    context "simple asc order" do
      include_context "simple asc order"

      it "should reduce total count by 1" do
      end
    end
  end
end

def block_values(key = header_key)
  fetch_blocks_from_header(fetch_header(key)).map { |b| b.values }
end

def fetch_header(key = header_key)
  CachedRecord::Store::Header.new(mock_store_adapter.read(key))
end

def fetch_blocks_from_header(header)
  header.meta_blocks.map(&:key).map {|k| CachedRecord::Store::Block.new(k, mock_store_adapter.read(k))}
end

def fetch_blocks(*keys)
  keys.map {|k| CachedRecord::Store::Block.new(k, mock_store_adapter.read(k))}
end

def build_meta_block(block_key, block_hash)
  keys, _values = block_hash.values_at(:keys, :values)

  keys_data = (0..(keys.length-1)).inject([]) do |arr, i|
    key = keys[i]
    hash = {meta: key, key: key}
    arr << hash
    arr
  end
  block_hash.merge(key: block_key, keys_data: keys_data)
end
