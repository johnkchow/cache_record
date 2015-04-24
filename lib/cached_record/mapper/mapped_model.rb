class CachedRecord
  class Mapper
    class MappedModel
      attr_reader :version, :model, :type

      def initialize(version:, model:, type:)
        @version = version
        @type = type
        @model = model
      end

      def attribute(name)
        @model.public_send(name)
      end

      def to_hash
        {
          version: @version,
          type: @type,
          data: model.to_hash
        }
      end
    end
  end
end
