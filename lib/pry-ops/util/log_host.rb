module PryOps::Util::LogHost

  # Set the name of the host on which the service log files are kept.
  attr_writer :log_host

  # Array of shell glob patterns which should match all relevant
  # application/service log files on the specified +log_host+.
  attr_accessor :log_file_patterns

  def initialize(*args)
    super
  end

  # Name of the host on which the service is running and where the
  # log files of this application/service are stored.  If +log_host+
  # is unspecified, +host+ is used instead.
  def log_host
    @log_host || host
  end

  # Return a list of log files existing on #log_host.
  def log_files
    raise "no log host specified for #{self}" unless log_host
    raise "no log file patterns specified for #{self}" unless log_file_patterns

    redirect_stderr = $DEBUG ? '' : '2>/dev/null'
    command = "ssh -oClearAllForwardings=yes '#{host}' 'sudo sh -c \"ls -1 #{log_file_patterns.join ' '} #{redirect_stderr}\"' #{redirect_stderr}"

    `#{command}`.split("\n")
  end

  # Yield an +IO+ object to the given block from which it can read
  # log output from JIRA, line by line.
  #
  # @example
  #   log_tail do |log|
  #     while line = log.readline
  #       puts line if line =~ / (ERROR|FATAL|CRITICAL|NOTICE): /i
  #     end
  #   end
  def log_tail(&block)
    raise "no log host specified for #{self}" unless log_host
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
