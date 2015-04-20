require 'spec_helper'

RSpec.describe CachedRecord::DataAdapter::Collection do
  class TestCollectionDataAdapter < CachedRecord::DataAdapter::Collection
    types :user, :blog

    def fetch_keys(ids, options)
      {
        user: [1,2,3],
        blog: [4,5,6]
      }
    end

    def fetch_batch_for_type(ids, type, options)
    end
  end

  subject do
    TestCollectionDataAdapter.new
  end

  describe "#fetch_batch" do
    it "should pass the options to hook method #fetch_batch_for_type"
  end

  describe "#fetch_meta_keys" do
    context "when the returned hash's keys don't match to the registered types" do
      it "should raise an AssertionError"
    end

    context "when the array of hashes are missing the 'id' or 'key' keys" do
      it "should raise an AssertionError"
    end
  end
end
