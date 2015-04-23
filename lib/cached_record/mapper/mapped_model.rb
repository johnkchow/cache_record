class CachedRecord
  class Mapper
    class MappedModel
      attr_reader :version, :model

      def initialize(version:, model:, type:)
        @version = version
        @type = type
        @model = model
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
