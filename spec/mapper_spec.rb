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

  describe "#normalize_data" do
    it "should return a hash value" do
      expect(subject.normalize_data(data_object)).to eq(prop: 'foo')
    end
  end

  describe "#map_data_object" do
    context "when passing raw data :raw_default as the name" do
      it "should return a model of the default type" do
        mapped_model = subject.map_data_object({prop: "default"}, name: :raw_default)

        model = mapped_model.model
        expect(model.prop).to eq("default")
        expect(model).to be_a(TestModel)
        expect(model).to_not be_a(TestChildModel)
      end
    end

    context "when passing raw data :raw_test_child as the name" do
      it "should return a mapped model of the default type" do
        mapped_model = subject.map_data_object({prop: "child"}, name: :raw_test_child)
        model = mapped_model.model
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
          type: :test_child,
          version: 1,
          data: {prop: 'foo'}
        )
      end
    end

    context "when getting mapping context based on mapping name" do
      it "should return a hash with meta data along with serialized data" do
        serialized = subject.serialize_data(data_object, name: :test_record_2)
        expect(serialized).to include(
          type: :test_child,
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
