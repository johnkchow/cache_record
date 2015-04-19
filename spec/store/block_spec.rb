require 'spec_helper'
require 'securerandom'

describe CachedRecord::Store::Block do
  describe "values" do
    let(:values) { [1,2,3,4,5,6] }
    let(:block_data) { build_block_data(values, order: :asc) }
    subject { described_class.new(*block_data) }

    context "when asc" do
      it "should return array in asc order" do
        expect(subject.values).to eq(values)
      end
    end

    context "when desc" do
      let(:values) { [6,5,4,3,2,1] }
      let(:block_data) { build_block_data(values, order: :desc) }
      it "should return array in desc order" do
        expect(subject.values).to eq(values)
      end
    end
  end

  describe "insert" do
    context "order asc" do
      let(:values) { [1,2,3,5,6] }
      let(:block_data) { build_block_data(values, order: :asc) }
      subject { described_class.new(*block_data) }
      it "inserts into middle correctly" do
        subject.insert(4, 4)
        expect(subject.values).to eq ([1,2,3,4,5,6])
      end

      it "inserts into end correctly" do
        subject.insert(7, 7)
        expect(subject.values).to eq ([1,2,3,5,6,7])
      end

      it "inserts into beginning correctly" do
        subject.insert(-1, -1)
        expect(subject.values).to eq ([-1,1,2,3,5,6])
      end
    end

    context "order desc" do
      let(:values) { [6,5,3,2,1] }
      let(:block_data) { build_block_data(values, order: :desc) }
      subject { described_class.new(*block_data) }
      it "inserts into middle correctly" do
        subject.insert(4, 4)
        expect(subject.values).to eq ([6,5,4,3,2,1])
      end

      it "inserts into beginning correctly" do
        subject.insert(7, 7)
        expect(subject.values).to eq ([7,6,5,3,2,1])
      end

      it "inserts into end correctly" do
        subject.insert(-1, -1)
        expect(subject.values).to eq ([6,5,3,2,1,-1])
      end
    end
  end
end

def build_block_data(values, size: values.length, order:, key: nil)
  keys = values.map { |i| get_item_key(i) }

  [
    key || SecureRandom.uuid,
    {
      keys: keys,
      values: values,
      order: order,
      size: size
    }
  ]
end

def get_item_key(item)
  if item.respond_to?(:id)
    item.id
  elsif item.is_a?(Hash)
    item[:id] || item['id']
  else
    item
  end
end
