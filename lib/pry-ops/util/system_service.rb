require 'shellwords'

# This module is a service class mixin that provides the service
# class with the ability to start, stop and restart the service
# on the remote host where the service is running.
module PryOps::Util::SystemService

  # Name of the operating system service (e.g., "tomcat6")
  attr_accessor :service_name

  # Starts the service on +host+, regardless of whether the
  # service is already running or not.  The caller should call
  # #service_running? before this method, if the start command
  # might fail when the service is already running.
  def start_service
    raise "service name not set for #{self}" unless service_name

    host_sudo "service #{Shellwords.escape service_name} " +
      "start >/dev/null 2>&1"
  end

  # Stops the service on +host+, regardless of whether the
  # service is already running or not.  The caller should call
  # #service_running? before this method, if the stop command
  # might fail when the service is already stopped.
  def stop_service
    raise "service name not set for #{self}" unless service_name

    host_sudo "service #{Shellwords.escape service_name} " +
      "stop >/dev/null 2>&1"
  end

  # Returns +true+ or +false+ depending on whether the service
  # is currently running on +host+.
  def service_running?
    raise "service name not set for #{self}" unless service_name

    host_sudo "service #{Shellwords.escape service_name} " +
      "status >/dev/null 2>&1", :fail_on_error => false
  end

  class << self

    def included(including_class)
      including_class.send :include, PryOps::Util::Host
    end

  end

end
