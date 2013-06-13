require 'pry'

require 'pry-ops'

class PryOps

  class Binding < Module

    def initialize(scope_name)
      singleton_class.class_eval do
        @name = scope_name
      end

      if scope_name.empty?
        nesting_level = 0
      else
        nesting_level = 1 + scope_name.chars.count { |c| c == '.' }
      end

      # Define context children.
      PryOps.application.services.map { |s|
        context_name = s.name.split('.')[0...-1].join('.')
        context_name.split('.')[0..nesting_level].join('.')
      }.uniq.select { |context_name|
        parent_context = context_name.split('.')[0...nesting_level].join('.')
        context_name != scope_name and scope_name == parent_context
      }.each { |context_name|
        name = context_name.split('.').last
        define_singleton_method name, lambda { Binding.new context_name }
      }

      # Define service children.
      PryOps.application.services.select { |s|
        context_name = s.name.split('.')[0...-1].join('.')
        scope_name == context_name
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
