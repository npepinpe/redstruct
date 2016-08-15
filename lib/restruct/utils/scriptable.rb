module Restruct
  module Utils
    module Scriptable
      def script_eval(source, values)
        id = "#{self.class.name}##{caller_locations(1, 1)[0].base_label}".freeze
        values = [values] unless values.is_a?(Array)
        @factory.script(id, source).eval(keys: [@key], argv: values)
      end
    end
  end
end
