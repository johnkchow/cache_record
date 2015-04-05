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

describe CacheRecord::Store::Header do
  describe "#block_keys_for_offset_limit" do
    tests.each do |test|
      context "block sizes are #{test[:block_sizes]}" do
        test[:tests].each do |t|
          offset, limit = t.first
          block_range, start_index = t.last
          context "when offset #{offset}, limit #{limit}" do
            it "should return block range #{block_range}, start_index #{start_index}" do
              header = CacheRecord::Store::Header.new(build_header_data(test[:block_sizes]))
              blocks, start = header.block_keys_for_offset_limit(offset, limit)
              expect(blocks).to eq(block_range.to_a)
              expect(start).to eq(start_index)
            end
          end
        end
      end
    end
  end
end

def build_header_data(block_sizes)
  blocks = []
  block_sizes.each_with_index do |count, index|
    blocks << {
      key: index,
      first_key: 1,
      last_key: 2,
      count: count,
      size: 1000
    }
  end
  {
    sort_key: 'id',
    order: :desc,
    blocks: blocks,
    total_count: block_sizes.inject(&:+)
  }
end
