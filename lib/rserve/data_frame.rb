
module Rserve
  # An R-centric container for storing data frame-ish data
  class DataFrame
    attr_accessor :rownames
    attr_accessor :hash

    # takes an array of structs and returns a data frame object
    def self.from_structs(array)
      names = array.first.members
      lengthwise_arrays = names.map { Array.new(names.size) }
      array.each_with_index do |struct,m|
        struct.values.each_with_index do |val,n|
          lengthwise_arrays[n][m] = val
        end
      end
      hash = {}
      names.zip(lengthwise_arrays) do |name, lengthwise_array|
        hash[name] = lengthwise_array
      end
      self.new(hash)
    end

    def colnames() @hash.keys end

    # takes an ordered hash, where the col_name is the key and the data rows
    # are an array of values.  The default ordering of the hash keys will be
    # used as the colnames.  This works great for ruby 1.9 (which remembers
    # ordering).  Use an OrderedHash for ruby 1.8.  The rownames can be used
    # to specify the names of the rows (remains nil if no values specified)
    def initialize(ordered_hash, rownames=nil)
      @hash = ordered_hash
      @rownames = rownames
    end

    def ==(other)
      (self.hash == other.hash) && (self.rownames == other.rownames)
    end
  end

end

class Hash
  def to_dataframe(rownames=nil)
    obj = Rserve::DataFrame.new(self)
    obj.rownames = rownames if rownames
    obj
  end
end
