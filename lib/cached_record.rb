require "cached_record/configuration"

require 'cached_record/store_adapter'
require 'cached_record/store/collection_fetcher'
require 'cached_record/factory'
require 'cached_record/error'
require "cached_record/util/assertion"

require "cached_record/mapper"
require "cached_record/mapper/mapped_model"

require "cached_record/data_adapter/collection"

require "cached_record/manager"

require "cached_record/model/fields"

require "cached_record/managed_collection"


require "cached_record/store/split_array"
require "cached_record/store/header/meta_block"
require "cached_record/store/header"
require "cached_record/store/block"
require "cached_record/store/block_collection"
require "cached_record/store/managed_item"

require "cached_record/version"

class CachedRecord
  class << self
    def config
      @config ||= Configuration.new
    end
  end
end
