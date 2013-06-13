class PryOps

  class Context

    def initialize(object_manager, scope)
      @object_manager = object_manager
      @scope = scope.dup
    end

    def __binding__
      Binding.new @scope.join('.')
    end

  end

  module ObjectManager

    def initialize
      super
      @scope = Array.new
      @services = Hash.new
    end

    def services
      @services.values
    end

    def define_service(service_class, service_name, *args, &block)
      # TODO: use &block
      service_name = service_class.scope_name(@scope, service_name)
      service = intern(:@services, service_class, service_name, *args)
      service
    end

    def intern(ivar, object_class, object_name, *args)
      if args.size > 0
        if instance_variable_get(ivar).has_key? object_name.to_s
          raise "#{object_class} #{object_name} cannot be redefined"
        end
      end

      instance_variable_get(ivar)[object_name.to_s] ||=
        object_class.new(object_name, *args)
    end

    def in_context(name, &block)
      @scope.push name
      context = Context.new self, @scope
      yield context if block_given?
      context
    ensure
      @scope.pop
    end

    def current_scope
      @scope.dup
    end

  end

  class Application

    include ObjectManager

    attr_accessor :saved_binding_stack

  end

  class << self

    def application
      @application ||= Application.new
    end

  end

  module DSL

    class << self

      def eval(&block)
        dsl = Object.new
        dsl.send :extend, PryOps::DSL
        dsl.instance_eval &block
      end

    end

    private

    # Declare a nested context.
    #
    # Example:
    #   context :testing do
    #     service :jenkins, :url => "http://jenkins/"
    #   end
    #
    def context(name, *args, &block)
      name = name.to_s if name.is_a? Symbol
      name = name.to_str if name.respond_to? :to_str
      unless name.is_a? String
        raise ArgumentError, "context name should be a Symbol or String (#to_str)"
      end
      PryOps.application.in_context(name, &block)
    end

    # Declare a service.
    #
    # Example:
    #   service :jenkins, :url => "http://jenkins/" do
    #     puts nodes
    #   end
    #
    def service(name, *args, &block)
      Service.define_service(name, *args, &block)
    end

  end

end
