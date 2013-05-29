require 'data_mapper'
require 'pry-ops'

module PryOps::Resource
  def self.included(klass)
    klass.send :include, DataMapper::Resource
    klass.send :extend, ClassMethods
  end

  module ClassMethods
    # Returns the default repository name for this model.
    def default_repository_name
      :pry_ops
    end
  end
end

DataMapper.setup(:pry_ops, "yaml:#{File.expand_path '~/.pry-ops/resources'}").
  resource_naming_convention =
  DataMapper::NamingConventions::Resource::UnderscoredAndPluralizedWithoutModule
