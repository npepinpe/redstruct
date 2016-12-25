# frozen_string_literal: true
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
        # Creates a method with the given id, which will create a constant and a method in the class.
        # This allows you to use defscript as a macro for your lua scripts, which gets translated to Ruby code at compile
        # time.
        # @param [String] id the script ID
        # @param [String] source the lua script source
        def defscript(id, source)
          constant = "SCRIPT_SOURCE_#{id.upcase}"
          class_eval <<~METHOD, __FILE__, __LINE__ + 1
          #{constant} = { id: '#{id}'.freeze, source: %(#{source}).freeze }.freeze
            def #{id}(keys: [], argv: [])
              script = @factory.scripts(#{constant}[:id], #{constant}[:source])
              raise Redstruct::Error, 'could not create script from factory' if script.nil?
              return script.eval(keys: keys, argv: argv)
            end
          METHOD
        end
      end
    end
  end
end
