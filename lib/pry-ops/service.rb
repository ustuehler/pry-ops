require 'pry-ops'

# The +Service+ class contains popular service classes and is also the
# base class for all of them.
#
# A service in PryOps is basically an API, or an instance of a service
# class, and service classes are Ruby classes which define the required
# parameters to access a particular API, such as the API endpoint URI
# for a "GitHub" service.
#
# @example Inheriting the +Service+ class and defining an attribute.
#   class PryOps::Service::GitHub < PryOps::Service
#     attr_accessor :endpoint
#
#     def initialize(*args)
#       @endpoint = "https://api.github.com"
#       super
#     end
#
#     def api
#       require 'github_api'
#       @api ||= ::Github.new do |config|
#         config.endpoint = endpoint unless endpoint.nil?
#       end
#     end
#   end
class PryOps::Service
  extend PryOps::Util::Autoload
  autoload_all_files_relative_to __FILE__

  attr_reader :name

  def initialize(service_name, attributes = {})
    @name = service_name.to_s
    attributes.each { |k, v| public_send("#{k}=", v) }
  end

  def inspect
    "#<#{self.class}:#{name.inspect}>"
  end

  def to_s
    name
  end

  class << self

    def service_class_by_type(type)
      return type if type.is_a? self

      candidates = constants.select { |c|
        # TODO: underscore_name to UnderscoreName
        type.to_s.downcase == c.to_s.downcase
      }

      if candidates.size == 1
        const_get candidates.first
      elsif candidates.size == 0
        raise "service type #{type.inspect} is unknown"
      else
        raise "service type #{type.inspect} is ambiguous" +
          " (matches: #{candidates.join ', '})"
      end
    end

    def define_service(name, *args, &block)
      if args.last.is_a? Hash and args.last.has_key? :type
        service_class = service_class_by_type(args.last[:type])
        args.last.delete :type
      else
        candidates = constants.select { |c|
          # TODO: CamelCase to camel_case
          name.to_s.downcase.include? c.to_s.downcase
        }

        if candidates.size != 1
          raise "unable to determine service class from service name " +
            "#{name.inspect}, must pass :type attribute"
        end

        service_class = const_get(candidates.first)
      end

      PryOps.application.define_service(service_class, name, *args, &block)
    end

    def scope_name(scope, service_name)
      (scope + [service_name]).join '.'
    end

  end

  # Autoload all user-defined service classes.
  Dir.glob(File.expand_path '~/.pry-ops/service/*.rb').sort.each do |file|
    const_name_candidates = File.read(file).lines.
      grep(/^\s*(?:module|class)\s+([^\s]+)/) { |v|
        $1.split('::').last
      }

    const_name = const_name_candidates.find { |name|
      underscore_name = name.
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase

      # A proc or lambda assigned to the "FooBar" const will be
      # used as the autoload symbol if the file name is "foo_bar.rb"
      # or "foobar.rb".
      basename = File.basename(file, '.rb')
      basename == underscore_name or basename == name.downcase
    }

    # Silently skip this file if no matching proc or lambda
    # constant was found inside.
    unless const_name
      warn "WARNING: can't find matching constant in #{file}"
      next
    end

    autoload const_name.to_sym, file.sub(/\.rb$/, '')
  end
end
