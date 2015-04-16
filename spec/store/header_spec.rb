require 'spec_helper'

tests = [
  {
    block_sizes: [5,5,5],
    tests: [
      [
        [2,5],
        [0..1,2]
      ],
      [
        [5,2],
        [1..1,0]
      ],
      [
        [7,8],
        [1..2,2]
      ],
      [
        [0,15],
        [0..2,0]
      ]
    ]
  }
]

RSpec::Matchers.define :be_same_block_data_as do |expected|
  match do |actual|
    expected == actual
  end
  failure_message do |actual|
    "expected that #{actual} would be same block data as #{expected}"
  end
end

RSpec::Matchers.define :have_same_start_index_as do |expected|
  match do |actual|
    expected == actual
  end

  failure_message do |actual|
    "expected that #{actual} would be the same starting index as #{expected}"
  end
end

RSpec.describe CachedRecord::Store::Header do
  describe "#block_keys_for_offset_limit" do
    tests.each do |test|
      context "block sizes are #{test[:block_sizes]}" do
        test[:tests].each do |t|
          offset, limit = t.first
          block_range, start_index = t.last
          context "when offset #{offset}, limit #{limit}" do
            it "should return block range #{block_range}, start_index #{start_index}" do
              header = CachedRecord::Store::Header.new(build_header_data(test[:block_sizes]))
              blocks, start = header.block_keys_for_offset_limit(offset, limit)
              expect(blocks).to be_same_block_data_as(block_range.to_a)
              expect(start).to eq(start_index)
            end
          end
        end
      end
    end
  end

  describe "find_block_for_key" do
    context "the block already exists for the key" do
      it "should return the block key" do
      end
    end
  end
end

RSpec.describe CachedRecord::Store::Header::MetaBlock do
  describe "#can_insert_between?" do
    context "when key lies between both block ranges" do
      context "both blocks are full" do
        context "order desc" do
          subject do
            data =  {
              key: "subject",
              size: 4,
              keys_data: [
                {key: 15, id: 15},
                {key: 14, id: 14},
                {key: 13, id: 13},
                {key: 10, id: 10},
              ]
            }
            described_class.new(data, :desc)
          end

          let(:other_block) do
            data = {
              key: "other_block",
              min_key: 3,
              max_key: 0,
              size: 4,
              count: 4,
              keys_data: [
                {key: 3, id: 3},
                {key: 2, id: 2},
                {key: 1, id: 1},
                {key: 0, id: 0},
              ]
            }
            described_class.new(data, :desc)
          end

          let(:key) { 8 }

          it "returns true" do
            expect(subject.can_insert_between?(key, other_block)).to eq(true)
          end
        end
      end
    end
  end
end

def build_header_data(block_sizes)
  blocks = []
  counter = 0
  block_sizes.each_with_index do |count, index|
    keys_data = (counter..(counter + count - 1)).map { |i| {key: i, id: i } }
    blocks << {
      key: index,
      size: 1000,
      keys_data: keys_data,
    }
    counter += 1
  end
  {
    sort_key: 'id',
    order: :asc,
    blocks: blocks,
  }
end
