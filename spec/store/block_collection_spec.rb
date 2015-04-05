require 'spec_helper'

describe CacheRecord::Store::BlockCollection do
  describe "#items" do
    subject do
      options = {
        adapter: mock_adapter,
        sort_key: :id,
        order: :desc,
        block_size: 100
      }
      described_class.new(header_key, options)
    end
    let(:header_key) { "header" }

    let(:mock_adapter) do
      mock = double("Adapter")
      allow(mock).to receive(:read).with(header_key).and_return(header_data)
      allow(mock).to receive(:read_multi) do |*keys|
        keys.inject({}) do |hash, key|
          value = block_data[key]
          hash[key] = value
          hash
        end
      end
      mock
    end

    let(:block_data) do
      {
        "block1" => {
          first_key: "1",
          last_key: "4",
          sort_key: "id",
          order: 'desc',
          size: 20,
          items: [1,2,3,4],
        },
        "block2" => {
          first_key: "5",
          last_key: "8",
          sort_key: "id",
          order: 'desc',
          size: 20,
          items: [5,6,7,8],
        },
        "block3" => {
          first_key: "5",
          last_key: "8",
          sort_key: "id",
          order: 'desc',
          size: 20,
          items: [9,10,11,12],
        },
      }
    end

    let(:header_data) do
      blocks = block_data.map {|k,b| b.merge(key: k, count: b[:items].length)}
      total_count = block_data.inject(0) {|c,(_,b)| c + b[:items].length }
      {
        total_count: total_count,
        blocks: blocks,
        sort_key: "id",
        order: "desc",
      }
    end

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
end
