require 'pry-ops/util'

module PryOps::Util::EnumerableFilter

  # Include this module in classes which also include ::Enumerable,
  # to define type-preserving wrappers for most (if not all) methods
  # of collections.
  #
  # Type-preserving means that, for instance, the #select method call
  # returns an instance of the class that it was called on, instead of
  # returning an Array.  Likewise, #group_by would then return a Hash
  # whose values are instances of the class that #group_by was called
  # on.
  #
  # For this to work, the including class must have a constructor that
  # accepts an Array of elements.
  module EnumerableFilter

    def select(&block)
      self.class.new(super(&block))
    end

    def reject(&block)
      self.class.new(super(&block))
    end

    def group_by(&block)
      hash = super(&block)
      hash.each do |key, value|
        hash[key] = self.class.new(value)
      end
      hash
    end

  end

end

#class ArrayWrapper
#  include Enumerable
#  include Util::EnumerableFilter
#
#  def initialize(entries)
#    @entries = entries
#  end
#
#  def each(&block)
#    @entries.each(&block)
#  end
#end
