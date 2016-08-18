module Restruct
  module Utils
    module Scriptable
      def script_eval(source, values: [], keys: [])
        id = "#{self.class.name}##{caller_locations(1, 1)[0].base_label}".freeze
        keys = [@key].concat(keys)
        script(source, id: id, values: values, keys: keys)
      end

      def script(source, id:, values: [], keys: [])
        id ||= "#{self.class.name}##{caller_locations(1, 1)[0].base_label}".freeze
        values = [values] unless values.is_a?(Array)
        keys = [keys] unless keys.is_a?(Array)
        @factory.script(id, source).eval(keys: keys, argv: values)
      end
    end
  end
end
