module Restruct
  class DefscriptHandler < YARD::Handlers::Ruby::Base
    GROUP_NAME = 'Lua Scripts'.freeze

    handles method_call(:defscript)
    namespace_only

    process do
      method_name = statement.parameters[0].jump(:ident).source
      method_body = strip_heredoc(statement.parameters[1].source)

      script = LuaScriptObject.new(namespace, method_name, scope)
      script.parameters = [['keys', []], ['values', []]]
      script.source = method_body
      script.source_type = :lua
      script.dynamic = true
      script.group = GROUP_NAME

      register(script)
    end

    def strip_heredoc(string)
      if string.start_with?('<<')
        lines = string.split("\n")
        string = lines[1...-1].join("\n").strip
      end

      return string
    end
    private :strip_heredoc

    class LuaScriptObject < YARD::CodeObjects::MethodObject
      attr_accessor :keys, :argv

      def initialize(*args)
        super
        @keys = 0
        @argv = 0
      end
    end

    class Tag < YARD::Tags::Tag
      def initialize(*args)
        super
        parse_text if object.is_a?(LuaScriptObject)
      end

      def parse_text
        before, types, text = YARD::Tags::DefaultFactory.extract_types_and_name_from_text(@text)
        @types = types || @types

        case @tag_name
        when ARGV_NAME
          object.argv += 1
          @text = "ARGV[#{object.argv}] #{text}"
        when KEYS_NAME
          object.keys += 1
          @text = "KEYS[#{object.keys}] #{text}"
        end
      end
      private :parse_text
    end
    YARD::Tags::Library.define_tag('ARGV', 'argv', Restruct::DefscriptHandler::Tag)
    YARD::Tags::Library.define_tag('KEYS', 'keys', Tag)
  end
end
