require 'pry-ops/util/autoload'

# +PryOps+ is a +Pry+ plugin for DevOps people.
module PryOps
  extend PryOps::Util::Autoload
  autoload_all_files_relative_to __FILE__
end

require 'pry-ops/environment'

# Trigger ``autoload'' definitions to load all service classes.
PryOps::Service.constants.each { |sym| PryOps::Service.const_get sym }

# Now that all data models should be loaded, call finalize.
DataMapper.finalize

# XXX: DataMapper requires a default repository
unless DataMapper::Repository.adapters.has_key? :default
  DataMapper.setup :default, 'sqlite::memory:'
end

# Create all the PryOps commands in Pry.
require 'pry-ops/commands'
