require 'pry-ops/util/autoload'

# +PryOps+ is a +Pry+ plugin for DevOps people.
module PryOps
  extend PryOps::Util::Autoload
  autoload_all_files_relative_to __FILE__
end

# Load all data models and call DataMapper.finalize.
require 'pry-ops/environment'
require 'pry-ops/service/github'
DataMapper.finalize

# XXX: DataMapper requires a default repository
unless DataMapper::Repository.adapters.has_key? :default
  DataMapper.setup :default, 'sqlite::memory:'
end

# Create all the PryOps commands in Pry.
require 'pry-ops/commands'
