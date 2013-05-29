require 'pry-ops'

# The +Service+ class contains popular service classes and is also the
# base class for all of them.
#
# A service in PryOps is basically an API, or an instance of a service
# class, and service classes are Ruby classes which define the properties
# of a particular API, such as the API endpoint URI for a "GitHub"
# service.
#
# @example Inheriting the +Service+ class and defining a property.
#   class PryOps::Service::GitHub < PryOps::Service
#     property :endpoint, String, :default => "https://api.github.com"
#
#     def api
#       require 'github_api'
#       @api ||= ::Github.new do |config|
#         config.endpoint = endpoint unless endpoint.nil?
#       end
#     end
#
#     after :save do
#       @api = nil
#     end
#   end
class PryOps::Service
  extend PryOps::Util::Autoload
  autoload_all_files_relative_to __FILE__

  include PryOps::Resource

  # Unique name of this service within an environment.
  property :name, String, :key => true, :required => true
  belongs_to :environment, :key => true

  # Ruby class name of the service.
  property :type, Discriminator

  # Hide modules included in this class (mostly DataMapper modules)
  # from Pry's "ls" command, by default.  Use "ls -v" to ignore the
  # ceiling.
  (Pry.config.ls.ceiling += self.included_modules.reject { |m|
    m.name.nil? or m.name =~ /^PryOps::/
  }).uniq!
end
