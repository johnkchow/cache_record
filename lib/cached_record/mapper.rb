class CachedRecord
  class Mapper
    class << self

      def model(model, options = {})
        type = options[:type] || :default
        model_mappings[type] = model

        if type != :default
          map("raw_#{type}".to_sym, type: type, mapper: :map_raw_data)
        end
      end

      def model_mappings
        @models ||= {}
      end

      def map(source, options = {})
        mappings[source] = default_options.merge(options)
      end

      def mappings
        # TODO: not thread safe
        @mappings ||= {
          raw_default: {mapper: :map_raw_data, type: :default}
        }
      end

      def version(v = nil)
        @version ||= 1

        @version = v if v

        @version
      end

      protected

      def default_options
        {
          type: :default
        }
      end
    end

    attr_reader :version

    def initialize(version: self.class.version)
      @version = version
    end

    def normalize_data(data_object, name: nil)
      mapped_model = map_data_object(data_object, name: name)
      mapped_model.model.to_hash
    end

    def map_data_object(data_object, name: nil)
      map_context = get_map_context!(data_object, name)

      model = build_model(map_context[:type])
      map(model, data_object, name: name)

      MappedModel.new(
        version: self.version,
        type: map_context[:type],
        model: model
      )
    end

    def from_raw_data(raw_data)
      type = raw_data[:type]

      map_data_object(raw_data[:data], name: "raw_#{type}")
    end

    def serialize_data(data_object, name: nil)
      mapped_model = map_data_object(data_object, name: name)

      mapped_model.to_hash
    end

    protected

    def map(model, data_object, name: nil)
      map_context = get_map_context!(data_object, name)

      mapper = map_context[:mapper]
      if mapper.is_a?(Symbol)
        self.send(mapper, model, data_object)
      end
      model
    end

    def map_raw_data(model, raw_data)
      model.from_hash(raw_data)
    end

    def build_model(type)
      model_class(type).new
    end

    def model_class(type)
      self.class.model_mappings[type.to_sym]
    end

    def get_map_context!(object, name = nil)
      if name
        options = self.class.mappings[name.to_sym]
      else
        options = self.class.mappings[object.class]
      end

      raise MappingError, "Cannot find mapping options for '#{name}'" unless options

      options
    end
  end
end
