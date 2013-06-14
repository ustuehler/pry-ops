require 'pry-ops/util/autoload'

# Utility modules for internal use in the pry-ops package.
module PryOps::Util
  extend PryOps::Util::Autoload
  autoload_all_files_relative_to __FILE__
end
