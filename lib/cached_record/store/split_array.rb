class CachedRecord
  class Store
    module SplitArray
      def split_array(array)
        split_index = (array.length / 2).to_i - 1
        first_part = array[0..split_index]
        last_part = array[(split_index + 1)..-1]

        [first_part, last_part]
      end
    end
  end
end
