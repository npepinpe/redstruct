# frozen_string_literal: true
module Redstruct
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
              script = @factory.scripts.get(#{constant}[:id])
              script ||= @factory.scripts.set(#{constant}[:id], #{constant}[:source])
              return script.eval(keys: keys, argv: argv)
            end
          METHOD
        end
      end
    end
  end
end
