# frozen_string_literal: true
require 'digest'

module Redstruct
  module Utils
    # Provides utility methods to add lua scripts to any class
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
          constant = "SCRIPT_#{id.upcase}"
          class_eval <<~METHOD, __FILE__, __LINE__ + 1
          #{constant} = { script: %(#{script}).freeze, sha1: Digest::SHA1.hexdigest(%(#{script})).freeze }.freeze
            def #{id}(keys: [], argv: [])
              return @factory.script(script: #{constant}[:script], sha1: #{constant}[:sha1]).eval(keys: keys, argv: argv)
            end
          METHOD
        end
      end
    end
  end
end
