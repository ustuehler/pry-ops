class PryOps
  module Util

    # +Autoload+ is a module that generates +autoload+ statements
    # automatically, from existing files and definitions therein.
    #
    # It should be used with +extend+ in other modules or classes
    # to provide them with the +autoload_all_files_relative_to+
    # method.
    #
    # == Example
    #
    # Consider the following files and definitions:
    #
    #   # lib/pry-ops.rb
    #   module PryOps
    #     extend PryOps::Util::Autoload
    #     autoload_all_files_relative_to __FILE__
    #   end
    #
    #   # lib/pry-ops/autoload_example.rb
    #   module PryOps::AutoloadExample
    #   end
    #
    # The above +autoload_all_files_relative_to+ statement would
    # be equivalent to the following +autoload+ statement:
    #
    #   module PryOps
    #     autoload :AutoloadExample, 'pry-ops/autoload_example'
    #   end
    #
    module Autoload
      # Since the +Autoload+ methods are made available in a
      # lot of modules, it's better that we hide them from the
      # "prying" eye of the Pry user. :)
      private

      def autoload_all_files_relative_to(base_module_file)
        if base_module_file =~ /^(.+\/lib)\/(.+).rb$/
          libdir = $1
          relative_path = $2
        else
          raise "can't find lib directory in #{base_module_file}"
        end

        Dir.chdir(libdir) do
          Dir.glob("#{relative_path}/*.rb").each do |file|
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

              # A module or class named "FooBar" will be used as the
              # autoload symbol if the file name is "foo_bar.rb" or
              # "foobar.rb".
              basename = File.basename(file, '.rb')
              basename == underscore_name or basename == name.downcase
            }

            # Silently skip this file if no matching class or module
            # name was found inside.
            next unless const_name

            autoload const_name.to_sym, file.sub(/\.rb$/, '')
          end
        end
      end
    end

  end
end
