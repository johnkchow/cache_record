require 'spec_helper'

describe CachedRecord::Store::BlockCollection do
  describe "#items" do
    subject do
      options = {
        adapter: mock_adapter,
        order: order,
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

    let(:header_data) do
      blocks = block_data.map {|k,b| b.merge(key: k, count: b[:keys].length)}
      total_count = block_data.inject(0) {|c,(_,b)| c + b[:keys].length }
      {
        total_count: total_count,
        blocks: blocks,
        order: order.to_s,
      }
    end

    context "when order is asc" do
      let(:order) { :asc }
      let(:block_data) do
        {
          "block1" => {
            first_key: 1,
            last_key: 4,
            order: :asc,
            size: 20,
            keys: [1,2,3,4],
            values: [1,2,3,4],
          },
          "block2" => {
            first_key: 5,
            last_key: 8,
            order: :asc,
            size: 20,
            keys: [5,6,7,8],
            values: [5,6,7,8],
          },
          "block3" => {
            first_key: 9,
            last_key: 12,
            order: :asc,
            size: 20,
            keys: [9,10,11,12],
            values: [9,10,11,12],
          },
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

    context "when order is desc" do
      let(:order) { :desc }
      let(:block_data) do
        {
          "block3" => {
            first_key: 12,
            last_key: 9,
            order: :desc,
            size: 20,
            keys: [12, 11, 10, 9],
            values: [12, 11, 10, 9],
          },
          "block2" => {
            first_key: 8,
            last_key: 5,
            order: :desc,
            size: 20,
            keys: [8, 7, 6, 5],
            values: [8, 7, 6, 5],
          },
          "block1" => {
            first_key: 4,
            last_key: 1,
            order: :desc,
            size: 20,
            keys: [4, 3, 2, 1],
            values: [4, 3, 2, 1],
          },
        }
      end

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
  end
end
