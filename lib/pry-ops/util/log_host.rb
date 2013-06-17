module PryOps::Util::LogHost

  # Name of the host on which the service is running and where the
  # log files of this application/service are stored.
  attr_accessor :host

  # Array of shell glob patterns which should match all relevant
  # application/service log files on the specified +host+.
  attr_accessor :log_file_patterns

  def initialize(*args)
    super
  end

  # Yield an +IO+ object to the given block from which it can read
  # log output from JIRA, line by line.
  def log_tail(&block)
    raise "no host specified for #{self}" unless host
    raise "no log file patterns specified for #{self}" unless log_file_patterns

    redirect_stderr = $DEBUG ? '' : '2>/dev/null'
    command = "ssh -oClearAllForwardings=yes '#{host}' 'sudo sh -c \"tail -n -0 -F #{log_file_patterns.join ' '} #{redirect_stderr}\"' #{redirect_stderr}"

    IO.popen(command) do |pipe|
      if block_given?
        yield pipe
      else
        while line = pipe.readline
          puts line
        end
      end
    end
  end

end
