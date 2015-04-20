class CachedRecord
  class Mapper
    @mutex = Mutex.new

    class << self

      def model(model, options = {})
        type = options[:type] || :default
        model_mappings[type] = model

        define_method("map_raw_#{type}") do |*args|
          self.map_raw_type(type, *args)
        end

        map("raw_#{type}".to_sym, method: "map_raw_#{type}")
      end

      def model_mappings
        @models ||= {}
      end

      def map(source, options = {})
        mappings[source] = default_options.merge(options)
      end

      def default_options
        #TODO
        {}
      end

      def mappings
        # TODO: not thread safe
        @mappings ||= {}
      end

      def version(v = nil)
        @version ||= 1

        @version = v if v

        @version
      end
    end

    def map(model, data_object, name = nil)
      unless map_options = get_map_options(data_object, name)
        raise MapperError, "Cannot find mapping options for #{data_object}"
      end

      mapper = map_options[:mapper]
      if mapper.is_a?(Symbol)
        self.send(mapper, model, data_object)
      end
      model
    end

    def normalize_data(data_object, type = :default)
      model = data_to_model(data_object)
      model.to_hash
    end

    def data_to_model(data_object, type = :default)
      model = build_model(type)
      map(model, data_object)
      model
    end

    def serialize_data(data_object, type = nil)
      data_hash = normalize_data(data_object)

      unless map_options = get_map_options(data_object, "raw_#{type}".to_sym)
        raise MapperError, "Cannot find mapping options for #{data_object}"
      end

      serialized = {
        version: self.class.version,
        data: data_hash,
      }

      if type = map_options[:type]
        serialized[:type] = type.to_s
      end

      serialized
    end

    protected

    def build_model(type, raw_data = {})
      model_class(type).new.tap do |m|
        m.from_hash(raw_data)
      end
    end


    def model_class(type)
      self.class.model_mappings[type.to_sym]
    end

    def get_map_options(object, name = nil)
      if name
        options = self.class.mappings[name]
      else
        options = self.class.mappings[object.class]
      end
      options
    end
  end
end
