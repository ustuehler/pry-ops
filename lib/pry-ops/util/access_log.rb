require 'pry-ops'

module PryOps::Util

  # Apache access log parser
  #
  # == Computing Statistics
  #
  # Get the top 10 requests as a Confluence wiki table:
  #
  #   >> access_log.top_10_requests
  #   ...
  #
  class AccessLog

    include Enumerable
    include EnumerableFilter

    def self.load_file(filename)
      new.parse_file(filename)
    end

    def initialize(input_or_entries = "")
      case input_or_entries
      when String, IO
        @entries = []
        parse input_or_entries
      else
        if input_or_entries.respond_to? :each
          @entries = input_or_entries
        else
          raise ArgumentError, "input_or_entries must respond to " +
            "#each: #{input_or_entries.inspect}"
        end
      end
    end

    # Calls block once for each accsess log entry in self, passing
    # that entry as a parameter.
    #
    # If no block is given, an enumerator is returned instead.
    #
    # @yieldparam [Entry]
    #
    # @return [AccessLog]
    def each(&block)
      @entries.each(&block)
    end

    # Parse access log lines from the given file.
    # (see #parse)
    def parse_file(filename)
      File.open(filename, 'r') { |f| parse f }
    end

    class Entry
      attr_accessor :source_ip, :timestamp, :request, :status,
        :serve_time, :bytes_received, :bytes_sent, :referer,
        :user_agent

      def bytes_per_second
        bytes / (serve_time / 1000000.0)
      end

      def request_type
        request =~ /^([^ ]+) / ? $1 : nil
      end

      def request_uri
        request =~ /^[^ ]+ ([^ ]+) / ? $1 : nil
      end

      def request_path
        request =~ /^[^ ]+ ([^? ]+)/ ? $1 : nil
      end

      def query_string
        request =~ /^[^ ]+ [^ ]+(\?[^ ]+) / ? $1 : nil
      end

      def http_version
        request =~ /^[^ ]+ [^ ]+ ([^ ]+)/ ? $1 : nil
      end

      def bytes
        bytes_received + bytes_sent
      end
    end

    # Parse access log lines from the given input object.
    # @param [#readline,#to_s,String,IO] input The input object to parse,
    #   which must respond to either the #readline or #to_s method calls.
    # @return [Array] The entries parsed and added to the previously
    #   existing entries.
    def parse(input)
      entries = []
      input = input.respond_to?(:readline) ? input : StringIO.new(input.to_s)
      begin
        while line = input.readline
          line.chomp!
          if line =~ /^([\d.]+|-) .* \[([^\]]+)\] "((?:\\"|[^"])+)" (\d+)(?: (\d+))?(?: (\d+))? (\d+) "([^"]+)" "([^"]*)"/
            # LogFormat "%{X-mobile-source-IP}i via %h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" debug_combined
            # - via 127.0.0.1 - - [15/May/2013:00:00:01 +0200] "GET /jkmanager?mime=txt HTTP/1.0" 200 26841 "-" "Wget/1.12 (linux-gnu)"
            # - via 10.38.252.251 - - [17/Jun/2013:00:28:01 +0200] "~\x81\x10\xb8\xa8\xa2\x9fd3x\x94\x12\"2\xedW\xe1d\xact\xfdB&\"\xe8\xb0!\xed\xfc\xe9M\x92\xf1\xf3\x97or\rzP}FN^\x18'\xad\x0c\x8a\xc9T\x82)\xb64\x04\xaa\xa8\xa9X\xb3V\x9a\x87\xa7G\xc7}O^~\"\xc3" 400 88 205 679 "-" "-"
            entry = Entry.new
            entry.source_ip = $1
            entry.request = $3
            entry.status = $4.to_i
            entry.serve_time = $5.to_i if $5 # in microseconds
            entry.bytes_received = $6.to_i if $6
            entry.bytes_sent = $7.to_i # including headers
            entry.referer = $8
            entry.user_agent = $9
            entry.timestamp = DateTime.parse($2.sub(/:/, ' '))
            entries << entry
          else
            raise "unrecognized input line: #{line}"
          end
        end
      rescue EOFError
      end

      @entries += entries
      entries
    end

    # Compute the total number of bytes transferred.
    def bytes
      map { |e| e.bytes }.reduce(:+)
    end

    # Compute the total number of bytes received.
    def bytes_received
      map { |e| e.bytes_received }.reduce(:+)
    end

    # Compute the total number of bytes sent.
    def bytes_sent
      map { |e| e.bytes_sent }.reduce(:+)
    end

    # Group entries by hour.
    def group_by_hour
      group_by { |e| e.timestamp.hour }
    end

    # Group entries by day ("YYYY-MM-DD").
    def group_by_day
      group_by { |e| e.timestamp.strftime '%Y-%m-%d' }
    end

    # Group access log entries by the hour of the day and return an
    # array whose elements are tuples of the form: [hour, bytes]
    #
    # @return [Array<Array<Fixnum,Fixnum>>]
    def bytes_per_hour
      group_by_hour.map { |hour, ents|
        [hour, ents.map { |e| e.bytes }.reduce(:+)]
      }.sort { |a,b|
        a[0] <=> b[0]
      }
    end

    # Compute the number of requests per hour.
    #
    # Returns an array whose elements are tuples of the form
    # [hour, count], sorted by the hour element.
    #
    # @return [Array<Array<Fixnum,Fixnum>>]
    def requests_per_hour
      group_by_hour.map { |hour, ents|
        [hour, ents.size]
      }.sort { |a,b|
        a[0] <=> b[0]
      }
    end

    # Compute the number of requests per day.
    #
    # Returns an array whose elements are tuples of the form
    # ["YYYY-MM-DD", count], sorted by the date element.
    #
    # @return [Array<Array<String,Fixnum>>]
    def requests_per_day
      group_by_day.map { |date, ents|
        [date, ents.size]
      }.sort { |a,b|
        a[0] <=> b[0]
      }
    end

    # Generate a table of entries grouped by the given attribute
    # (like :request, or :source_ip) that contribute the most to
    # the overall I/O of the total valume of data transferred.
    #
    # @param [Symbol] attribute
    #   The attribute by which to group (e.g., :request,
    #   :source_ip, or :user_agent).  This must be an attribute
    #   (or existing unary method) of each access log entry.
    #
    # @param [Fixnum] limit
    #   An upper limit on the number of table rows to return.
    #
    # @return [Array]
    #   The table, whose elements are of the form [bytes, count,
    #   attribute], ordered by the number of bytes transferred.
    def top(attribute, limit = 10)
      if attribute.respond_to? :call
        getter = attribute
      else
        getter = proc { |e| e.send(attribute) }
      end

      group_by { |e|
        getter.call(e)
      }.map { |attr, ents|
        [ents.map { |e| e.bytes }.reduce(:+), ents.count, attr]
      }.sort { |a,b|
        b[0] <=> a[0]
      }.first(limit)
    end

    # Generate a table of HTTP requests that contribute the most to
    # the overall I/O of the virtual host.  The table is formatted
    # in wiki markup for Atlassian Confluence.
    #
    # @return [String]
    #   The table of requests in wiki markup format.
    def top_10_requests
      "|| Volume || Count || Request ||\n" +
      top(:request).map { |bytes, count, request|
        "| #{'%.1f' % (bytes / 1024.0 / 1024.0)} MB " +
        "| #{count} | #{request} |\n"
      }.join
    end

    # Generate a table of source IPs that contribute the most to
    # the overall I/O of the virtual host.  The table is formatted
    # in wiki markup for Atlassian Confluence.
    #
    # @return [String]
    #   The table of source IPs in wiki markup format.
    def top_10_source_ips
      "|| Volume || Count || Source IP ||\n" +
      top(:source_ip).map { |bytes, count, source_ip|
        "| #{'%.1f' % (bytes / 1024.0 / 1024.0)} MB " +
        "| #{count} | #{source_ip} |\n"
      }.join
    end

    # Generates a chart that compares the volume of data transferred
    # via GET vs. PUT requests.
    def request_type_volume_chart
      require 'gruff'

      g = Gruff::Bar.new
      g.title = 'Bytes Transferred per Request Type'
      group_by { |e| e.request_type }.each { |request_type, entries|
        g.data(request_type, [entries.map { |e| e.bytes }.reduce(:+)])
      }
      g
    end

    # Group entries by hour of the day and return a list of tuples
    # of the form: [HOUR, AVG_KILOBYTES_PER_SECOND_PER_REQUEST]
    def kbps_per_request_by_hour(bytes_attribute = :bytes)
      group_by { |e|
        e.timestamp.hour
      }.map { |hour, ents|
        [hour, ents.map { |e|
          (e.send(bytes_attribute) / 1024.0) / (e.serve_time / 1000000.0) / ents.size
        }.reduce(:+)]
      }.sort { |a,b|
        a[0] <=> b[0]
      }
    end

    # Generates a chart that shows an hourly breakdown of the
    # average transfer speed per request.
    def transfer_speed_chart(bytes_attribute = :bytes)
      require 'gruff'

      g = Gruff::Line.new
      g.title = "Hourly average KB/s"

      g.labels = (0..23).inject({}) { |labels, hour|
        labels[hour] = hour.to_s
        labels
      }

      data = []
      select { |e| e.bytes < 1.megabyte }.
        kbps_per_request_by_hour(bytes_attribute).
        each { |hour, speed| data[hour] = speed }
      g.data("< 1MB", data)

      data = []
      select { |e| e.bytes >= 1.megabyte }.
        kbps_per_request_by_hour(bytes_attribute).
        each { |hour, speed| data[hour] = speed }
      g.data(">= 1MB", data)

      data = []
      select { |e| e.serve_time >= 1000000 }.
        kbps_per_request_by_hour(bytes_attribute).
        each { |hour, speed| data[hour] = speed }
      g.data("requests >= 1s", data)

      g
    end

  end

end
