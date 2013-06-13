# Nagios service class.
#
# The #api method returns an instance of the Nagios API (nagiosharder).
class PryOps::Service::Nagios < PryOps::Service
  # URI of the API endpoint.
  attr_accessor :base_uri

  # Nagios API version.
  attr_accessor :version

  # Username to authenticate with.
  attr_accessor :username

  # Password to authenticate with.
  attr_accessor :password

  # Time format which is used by Nagios.
  attr_accessor :time_format

  def initialize(*args)
    @version ||= 3
    super
  end

  # Returns the API instance for this service, which is an instance
  # of Mobile::JIRA::Client.
  def api
    require 'nagiosharder'

    @api ||= NagiosHarder::Site.new(base_uri, username, password, version)
    @api.nagios_time_format = time_format if time_format
    @api
  end
end
