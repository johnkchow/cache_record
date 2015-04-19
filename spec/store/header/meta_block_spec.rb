require 'spec_helper'

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
                {key: 15, meta: 15},
                {key: 14, meta: 14},
                {key: 13, meta: 13},
                {key: 10, meta: 10},
              ]
            }
            described_class.new(data, :desc)
          end

          let(:other_block) do
            data = {
              key: "other_block",
              size: 4,
              keys_data: [
                {key: 3, meta: 3},
                {key: 2, meta: 2},
                {key: 1, meta: 1},
                {key: 0, meta: 0},
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

  describe "#insert" do
    context "order desc, not full" do
      subject do
        data =  {
          key: "subject",
          size: 3,
          keys_data: [
            {key: 15, meta: 15},
            {key: 13, meta: 13},
          ]
        }
        described_class.new(data, :desc)
      end

      it "should insert the (meta_key, key, value) tuple in the middle" do
        subject.insert(14, 14, 1)
        expect(subject.keys_data).to eq([
          {key: 15, meta: 15},
          {key: 14, meta: 14},
          {key: 13, meta: 13},
        ])
      end
    end
  end
end
