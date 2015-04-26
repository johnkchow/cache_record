class CachedRecord
  class Error < StandardError; end

  class MappingError < Error; end

  class RemovedError < Error; end
end
