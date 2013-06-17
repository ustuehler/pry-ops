# LDAP service class
class PryOps::Service::LDAP < PryOps::Service

  attr_accessor :host
  attr_accessor :bind_username, :bind_password
  attr_accessor :base_dn
  attr_accessor :accounts_dn, :accounts_filter

  def api
    unless @api
      require 'ldap'

      api = ::LDAP::SSLConn.new host, ::LDAP::LDAPS_PORT
      api.bind bind_username, bind_password

      @api = api
    end

    @api
  end

  # NB: This method seems to truncate results at 1000 items.
  def all_users
    result = []
    api.search(accounts_dn, ::LDAP::LDAP_SCOPE_SUBTREE, accounts_filter) do |user|
      result << user.to_hash
    end
    result
  end

  def get_user!(username)
    filter = "(&#{accounts_filter}(sAMAccountName=#{username}))"
    result = nil

    api.search(accounts_dn, ::LDAP::LDAP_SCOPE_SUBTREE, filter) do |user|
      raise "multiple LDAP users: #{username}" unless result.nil?
      result = user.to_hash
    end

    raise "LDAP user not found: #{username}" if result.nil?
    result
  end

end
