require 'shellwords'

# Service class mixin which makes a service aware of the host
# system that it is running on.
#
# By including this class, a service class gains the ability 
# to execute remote commands via SSH on the system that hosts
# the service.
module PryOps::Util::Host

  # Name or IP address of the host system running a set of
  # services.
  attr_accessor :host

  # Used internally by PryOps::Util::Host.
  class SSHCommand

    attr_accessor :fail_on_error

    # Initializes an SSH shell command line.
    def initialize(host, command, options = {})
      @host = host
      @command = Shellwords.escape command

      @fail_on_error = true

      options.each { |k, v| public_send("#{k}=", v) }
    end

    # Returns the full SSH command line (a shell command) to
    # be passed to Kernel#system.
    def to_s
      "ssh -o ClearAllForwardings=yes '#{@host}' #{@command}"
    end

    # Executes the command according to the options passed in
    # the constructor.
    def execute
      if system(to_s)
        true
      else
        raise "Command failed: #{to_s}" if fail_on_error
        false
      end
    end

  end

  # Execute a Bourne shell command on the +host+ and act on the
  # command's exit code.  If the exit code is zero, +true+ is
  # returned; otherwise, depending on the :fail_on_error option,
  # an exception is raised or +false+ is returned.
  def host_sh(command, options = {})
    SSHCommand.new(host, command, options).execute
  end

  # Execute a Bourne shell command using sudo(8) on the +host+
  # and act on the command's exit code.  If the exit code is zero,
  # +true+ is returned; otherwise, depending on the :fail_on_error
  # option, an exception is raised or +false+ is returned.
  def host_sudo(command, options = {})
    host_sh "sudo -- #{command}", options
  end

end
