require 'pry-ops/util'

# +PryOps+ is a +Pry+ plugin for DevOps people.
class PryOps

  extend PryOps::Util::Autoload
  autoload_all_files_relative_to __FILE__

  class << self

    # (see PryOps::DSL#service)
    def service(name, *args, &block)
      PryOps::DSL.eval do
        service(name, *args, &block)
      end
    end

    # (see PryOps::DSL#context)
    def context(name, &block)
      PryOps::DSL.eval do
        context(name, &block)
      end
    end

    # (see PryOps::Application#services)
    def services
      application.services
    end

  end # << self

end

# Load the PryOps DSL.
require 'pry-ops/dsl_definition'

# Create all the PryOps commands in Pry.
require 'pry-ops/commands'
