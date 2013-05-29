require 'pry-ops'

# The +GitHub+ service provide access to the GitHub API of either
# https://github.com or a private instance, either anonymously or
# authenticated as a particular user.
#
# @example Using the API anonymously.
#   api = PryOps::Service::GitHub.new.api
#
# @example Listing repositories of the "github" user.
#   res = api.repos.list :user => 'github'
#   res.select { |repo| repo.name =~ /github/ }.map { |repo| repo.name }
#   # => ["develop.github.com", "developer.github.com",
#   #  "dodgeball.github.com", "github-services"]
#
class PryOps::Service::GitHub < PryOps::Service
  # URI of the API endpoint of the GitHub instance. (optional)
  property :endpoint, String

  # Returns the API instance for this service, which is an instance
  # of ::Github from the "github_api" gem.  See the documentation
  # for that class or https://github.com/peter-murach/github#readme
  # for usage instructions and examples.
  def api
    require 'github_api'

    @api ||= ::Github.new do |config|
      config.endpoint = endpoint unless endpoint.nil?
    end
  end

  # Forget about the current API instance and create a new one when
  # this object is saved or updated.
  after :save do
    @api = nil
  end
end
