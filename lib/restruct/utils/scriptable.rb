module Restruct
  module Utils
    module Scriptable
      def self.included(includer)
        includer.extend(ClassMethods)
      end

      def script(id, source)
        return self.class.script_cache.synchronize do
          self.class.script_cache[id] = @factory.script(source) if self.class.script_cache[id].nil?
          self.class.script_cache[id]
        end
      end

      def script_eval(source, values)
        id = caller_locations(1, 1)[0].label
        values = [values] unless values.is_a?(Array)
        script(id, source).eval(keys: [@key], argv: values)
      end

      module ClassMethods
        def script_cache
          return @script_cache ||= begin
            cache = {}
            cache.extend(MonitorMixin)
            cache
          end
        end
      end
    end
  end
end
