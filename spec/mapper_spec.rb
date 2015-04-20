require 'spec_helper'

RSpec.describe CachedRecord::Mapper do
  class TestModel
    attr_accessor :prop

    def initialize(attributes = {})
      from_hash(attributes)
    end

    def to_hash
      {
        prop: @prop,
      }
    end

    def from_hash(attributes)
      @prop = attributes[:prop]
    end
  end

  class TestRecord
    def prop
      'foo'
    end
  end

  class TestMapper < CachedRecord::Mapper
    model TestModel

    version 1

    map TestRecord, mapper: :map_test_record, type: :test_model

    def map_test_record(model, object)
      model.prop = object.prop
    end
  end

  subject { TestMapper.new }

  let(:data_object) { TestRecord.new }

  describe "#map" do

    it "should call the mapping" do
      model = TestModel.new
      expect { subject.map(model, data_object) }.to change { model.prop }.from(nil).to('foo')
    end
  end

  describe "#normalize_data" do
    it "should return a hash value" do
      expect(subject.normalize_data(data_object)).to eq(prop: 'foo')
    end
  end

  describe "#serialize_data" do
    it "should return a hash with meta data along with serialized data" do
      serialized = subject.serialize_data(data_object)
      expect(serialized).to include(
        type: 'test_model',
        version: 1,
        data: {prop: 'foo'}
      )
    end
  end
end
