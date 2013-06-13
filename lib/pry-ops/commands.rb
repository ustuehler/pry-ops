require 'pry'

require 'pry-ops'

class PryOps

  class Binding < Module

    def initialize(scope_name)
      singleton_class.class_eval do
        @name = scope_name
      end

      PryOps.application.services.map { |s|
        s.name.split('.')[0..-2].join('.')
      }.uniq.select { |context_name|
        parent_context = context_name.split('.')[0..-2].join('.')
        context_name != scope_name and scope_name == parent_context
      }.each { |context_name|
        name = context_name.split('.').last
        define_singleton_method name, lambda { Binding.new context_name }
      }

      PryOps.application.services.select { |s|
        service_context = s.name.split('.')[0..-2].join('.')
        scope_name == service_context
      }.each { |s|
        name = s.name.split('.').last
        define_singleton_method name, lambda { s }
      }
    end

    def name
      singleton_class.class_eval do
        @name.empty? ? 'main' : @name
      end
    end

    def inspect
      name
    end

    def to_s
      name
    end

    Pry.config.ls.ceiling << self
  end

end

module PryOps::Command

  class OpsMode < Pry::ClassCommand
    match 'ops-mode'
    group 'Operations Mode'
    description 'Toggle ops mode. Switch to an ops context.'

    banner <<-'BANNER'
      Toggle ops mode. Switch the context to an ops context, which contains
      mostly just services and nested contexts.
    BANNER

    def process
      if PryOps.application.saved_binding_stack
        _pry_.binding_stack = PryOps.application.saved_binding_stack
        PryOps.application.saved_binding_stack = nil
      else
        PryOps.application.saved_binding_stack = _pry_.binding_stack
        _pry_.binding_stack = [PryOps::Binding.new('').__binding__]
      end
    end
  end

  Pry::Commands.add_command(OpsMode)
end
