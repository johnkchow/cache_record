class CacheRecord
  module Util
    module Assertion
      class AssertError < StandardError; end

      def assert(*args)
        msg = args.first
        case args.length
        when 1
          value = yield
        when 2
          value = args.last
        else
          raise ArgumentError
        end

        raise AssertError, "Assertion failed: #{msg}" unless value
      end
    end
  end
end
