require 'spec_helper'
require 'securerandom'

describe CachedRecord::Store::Block do
  describe "items" do
    let(:items) { [1,2,3,4,5,6] }
    let(:block_data) { build_block_data(items, order: :asc) }
    subject { described_class.new(*block_data) }

    context "when asc" do
      it "should return array in asc order" do
        expect(subject.items).to eq(items)
      end
    end

    context "when desc" do
      let(:items) { [6,5,4,3,2,1] }
      let(:block_data) { build_block_data(items, order: :desc) }
      it "should return array in desc order" do
        expect(subject.items).to eq(items)
      end
    end
  end

  describe "insert" do
    context "order asc" do
      let(:items) { [1,2,3,5,6] }
      let(:block_data) { build_block_data(items, order: :asc) }
      subject { described_class.new(*block_data) }
      it "inserts into middle correctly" do
        subject.insert(4, 4)
        expect(subject.items).to eq ([1,2,3,4,5,6])
      end

      it "inserts into end correctly" do
        subject.insert(7, 7)
        expect(subject.items).to eq ([1,2,3,5,6,7])
      end

      it "inserts into beginning correctly" do
        subject.insert(-1, -1)
        expect(subject.items).to eq ([-1,1,2,3,5,6])
      end
    end

    context "order desc" do
      let(:items) { [6,5,3,2,1] }
      let(:block_data) { build_block_data(items, order: :desc) }
      subject { described_class.new(*block_data) }
      it "inserts into middle correctly" do
        subject.insert(4, 4)
        expect(subject.items).to eq ([6,5,4,3,2,1])
      end

      it "inserts into beginning correctly" do
        subject.insert(7, 7)
        expect(subject.items).to eq ([7,6,5,3,2,1])
      end

      it "inserts into beginning correctly" do
        subject.insert(-1, -1)
        expect(subject.items).to eq ([6,5,3,2,1,-1])
      end
    end
  end
end

def build_block_data(items, size: items.length, order:, key: nil)
  keys = items.map { |i| get_item_key(i) }

  [
    {
      keys: keys,
      values: items,
    },
    {
      order: order,
      size: size,
      key: key || SecureRandom.uuid
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
