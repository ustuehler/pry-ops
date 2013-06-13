require 'pry-ops/util/autoload'

# +PryOps+ is a +Pry+ plugin for DevOps people.
class PryOps
  extend PryOps::Util::Autoload
  autoload_all_files_relative_to __FILE__
end

# Load the PryOps DSL.
require 'pry-ops/dsl_definition'

# Create all the PryOps commands in Pry.
require 'pry-ops/commands'
