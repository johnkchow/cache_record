class CachedRecord
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

        unless value
          raise AssertError, "Assertion '#{msg}' failed"
        end
      end
    end
  end
end
