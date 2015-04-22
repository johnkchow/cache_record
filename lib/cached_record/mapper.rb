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

      def default_options
        #TODO
        {
          type: :default
        }
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
    end

    def map(model, data_object, name: nil)
      map_context = get_map_context!(data_object, name)

      mapper = map_context[:mapper]
      if mapper.is_a?(Symbol)
        self.send(mapper, model, data_object)
      end
      model
    end

    def normalize_data(data_object, name: nil)
      model = data_to_model(data_object, name: name)
      model.to_hash
    end

    def data_to_model(data_object, name: nil)
      map_context = get_map_context!(data_object, name)

      model = build_model(map_context[:type])
      map(model, data_object, name: name)
      model
    end

    def serialize_data(data_object, name: nil)
      data_hash = normalize_data(data_object, name: name)

      map_context = get_map_context!(data_object, name)

      {
        version: self.class.version,
        type: map_context[:type].to_s,
        data: data_hash,
      }
    end

    protected

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
