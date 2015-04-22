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

  class TestChildModel < TestModel; end

  class TestRecord
    def prop
      'foo'
    end
  end

  class TestMapper < CachedRecord::Mapper
    model TestModel
    model TestChildModel, type: :test_child

    version 1

    map TestRecord, mapper: :map_test_record, type: :test_child

    map :test_record_2, mapper: :map_test_record_2, type: :test_child

    def map_test_record(model, object)
      model.prop = object.prop
    end

    def map_test_record_2(model, object)
      model.prop = object.prop + "2"
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

  describe "#data_to_model" do
    context "when passing raw data :raw_default as the name" do
      it "should return a model of the default type" do
        model = subject.data_to_model({prop: "default"}, name: :raw_default)
        expect(model.prop).to eq("default")
        expect(model).to be_a(TestModel)
        expect(model).to_not be_a(TestChildModel)
      end
    end

    context "when passing raw data :raw_test_child as the name" do
      it "should return a model of the default type" do
        model = subject.data_to_model({prop: "child"}, name: :raw_test_child)
        expect(model.prop).to eq("child")
        expect(model).to be_a(TestChildModel)
      end
    end
  end

  describe "#serialize_data" do
    context "when getting mapping context based on data_object class" do
      it "should return a hash with meta data along with serialized data" do
        serialized = subject.serialize_data(data_object)
        expect(serialized).to include(
          type: 'test_child',
          version: 1,
          data: {prop: 'foo'}
        )
      end
    end

    context "when getting mapping context based on mapping name" do
      it "should return a hash with meta data along with serialized data" do
        serialized = subject.serialize_data(data_object, name: :test_record_2)
        expect(serialized).to include(
          type: 'test_child',
          version: 1,
          data: {prop: 'foo2'}
        )
      end
    end

    context "when passing an invalid name" do
      it "should raise a MappingError" do
        expect { subject.serialize_data(data_object, name: :test_record_unknown) }.to raise_error(CachedRecord::MappingError)
      end
    end
  end
end
