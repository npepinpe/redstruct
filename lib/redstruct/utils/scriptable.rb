# frozen_string_literal: true

require 'digest'

module Redstruct
  module Utils
    # Provides utility methods to add lua scripts to any class
    # There is a built-in Lua debugger, but if you don't want to start
    # your server in debug mode, you can use the ECHO command and the
    # MONITOR command to use basic print-debugging
    module Scriptable
      # Callback called whenever the module is included. Adds all methods under ClassMethods as class methods of the
      # includer.
      def self.included(base)
        base.extend(ClassMethods)
      end

      # Class methods added when the module is included at the class level (i.e. extend)
      module ClassMethods
        # Creates a method with the given id, which will create a constant and a method in the class. This allows you
        # to use defscript as a macro for your lua scripts, which gets translated to Ruby code at compile time.
        # @param [String] id the script ID
        # @param [String] script the lua script source
        def defscript(id, script)
          raise ArgumentError, 'no script given' unless !script&.empty?

          script = script.strip
          constant = "SCRIPT_#{id.upcase}"

          if const_defined?(constant)
            Redstruct.logger.warn("cowardly aborting defscript #{id}; constant with name #{constant} already exists!")
            return
          end

          if method_defined?(id)
            Redstruct.logger.warn("cowardly aborting defscript #{id}; method with name #{id} already exists!")
            return
          end

          class_eval <<~METHOD, __FILE__, __LINE__ + 1
            #{constant} = { script: %(#{script}).freeze, sha1: Digest::SHA1.hexdigest(%(#{script})).freeze }.freeze
              def #{id}(keys: [], argv: [])
                return @factory.script(#{constant}[:script], sha1: #{constant}[:sha1]).eval(keys: keys, argv: argv)
              end
          METHOD
        end
      end
    end
  end
end
