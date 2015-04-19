class CachedRecord
  class Mapper
    @mutex = Mutex.new

    class << self

      def model(model = nil)
        if model
          @model = model
        else
          @model
        end
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
    end
  end

  def initialize
  end

  def map(model, object, name = nil)
    unless map_options = get_map_options(name, object)
      raise MapperError, "Cannot find mapping options for #{object}"
    end

    mapper = map_options[:mapper]
    if mapper.is_a?(Symbol)
      self.send(mapper, model, object)
    end
  end

  def normalize_data(data)
    model = model_class.new
    map(model, data).to_hash
  end

  def build_model(raw_data)
    model_class.new.tap do |m|
      m.from_hash(raw_data)
    end
  end

  protected

  def get_map_options(name, object)
    if name
      options = self.class.mappings[name]
    else
      options = self.class.mappings[object.class]
    end
    options
  end
end
