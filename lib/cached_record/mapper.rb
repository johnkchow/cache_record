class CachedRecord
  class Mapper
    @mutex = Mutex.new

    class << self

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

  def initialize(raw_data)
    @model = serialize_model(raw_data)
  end

  def map(model, object)
  end

  def serialize_model(raw_data)
  end

  protected
end
