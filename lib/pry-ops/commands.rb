require 'ostruct'

require 'highline/import'
require 'pry'

module PryOps

  module Command
    @@ops_mode = false unless defined? @@ops_mode

    def ops_mode?
      @@ops_mode ? true : false
    end

    def ops_mode=(v)
      @@ops_mode = v
    end

    # Let the user pick an environment.
    def ask_for_environment
      choices = Environment.all.map { |e| e.name }
      environment = ask("Select environment: ", choices) do |q|
        q.readline = true
      end
      environment = Environment.get! environment
    end

    # Make environments and services available as sticky locals.
    def add_sticky_locals(environment)
      Environment.all.each do |e|
        struct = OpenStruct.new
        e.services.each do |s|
          struct.public_send("#{s.name}=", s)
        end
        _pry_.sticky_locals[e.name.to_sym] = proc { struct }
      end

      environment.services.each do |s|
        _pry_.sticky_locals[s.name.to_sym] = proc { s }
      end
    end

    def remove_sticky_locals
      _pry_.sticky_locals.each { |k, v|
        if v.is_a? Proc and v.source_location[0] == __FILE__
          _pry_.sticky_locals.delete k
        end
      }
    end
  end

  class Command::OpsMode < Pry::ClassCommand
    match 'ops-mode'
    group 'Operations Mode'
    description 'Toggle ops mode. Bring in prompt and locals.'

    banner <<-'BANNER'
      Toggle ops mode. Bring in ops context prompt and automatic sticky
      local variables.
    BANNER

    include PryOps::Command

    def process
      if ops_mode?
        remove_sticky_locals
        self.ops_mode = false
      else
        self.ops_mode = true
        add_sticky_locals ask_for_environment
      end
    end
  end

  Pry::Commands.add_command(PryOps::Command::OpsMode)

  class Command::OpsEnv < Pry::ClassCommand
    match 'ops-env'
    group 'Operations Mode'
    description 'Change ops environment.'

    banner <<-'BANNER'
      Change the ops environment.
    BANNER

    include PryOps::Command

    def process
      if ops_mode?
        remove_sticky_locals
        add_sticky_locals ask_for_environment
      else
        output.puts "Ops mode isn't enabled."
      end
    end
  end

  Pry::Commands.add_command(PryOps::Command::OpsEnv)
end
