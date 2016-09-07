module Restruct
  module Utils
    module Scriptable
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def defscript(id, source)
          constant = "SCRIPT_SOURCE_#{id.upcase}"
          class_eval <<~METHOD, __FILE__, __LINE__ + 1
          #{constant} = { id: '#{id}'.freeze, source: %(#{source}).freeze }.freeze
            def #{id}(keys: [], argv: [])
              return @factory.script(#{constant}[:id], #{constant}[:source]).eval(keys: keys, argv: argv)
            end
          METHOD
        end
      end
    end
  end
end
