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

  # This class builds a "tail" command line based on the options
  # given to the constructor.
  #
  # @example Produce a command to show the last 30 lines of a file.
  #   TailCommand.new :last => 30
  class TailCommand

    attr_accessor :discard_stderr
    attr_accessor :follow
    attr_accessor :last
    attr_accessor :quiet

    # Initialize a tail(1) command line for the Bourne Shell.
    def initialize(glob_patterns, options = {})
      @glob_patterns = glob_patterns

      @discard_stderr = true
      @follow = true
      @quiet = false

      options.each { |k, v| public_send("#{k}=", v) }
    end

    # Return a shell command which calls tail(1) on the files that
    # match the glob patterns and with command line options according
    # to the options passed to #initialize.
    def to_s
      "tail #{@follow ? '-F' : ''} -n #{@last || 0} " +
        (@quiet ? '-q ' : '') +
        @glob_patterns.join(' ') +
        (@discard_stderr ? ' 2>/dev/null' : '')
    end

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
  def log_tail(options = {}, &block)
    raise "no log host specified for #{self}" unless log_host
    raise "no log file patterns specified for #{self}" unless log_file_patterns

    unless options.has_key? :discard_stderr
      options[:discard_stderr] = !$DEBUG
    end

    tail_command = TailCommand.new log_file_patterns, options

    command = "ssh -oClearAllForwardings=yes '#{host}' " +
      "'sudo sh -c \"#{tail_command}\"'" +
      (options[:discard_stderr] ? ' 2>/dev/null' : '')

    IO.popen(command) do |pipe|
      if block_given?
        yield pipe
      else
        begin
          while line = pipe.readline
            puts line
          end
        rescue EOFError
          # ignore
        end
      end
    end
  end

end
