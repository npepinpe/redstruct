# frozen_string_literal: true

module YARD
  class DefscriptHandler < YARD::Handlers::Ruby::Base # :nodoc:
    GROUP_NAME = 'Lua Scripts'

    handles method_call(:defscript)
    namespace_only

    process do
      method_name = statement.parameters[0].jump(:ident).source
      method_body = strip_heredoc(statement.parameters[1].source)

      script = YARD::CodeObjects::MethodObject.new(namespace, method_name, scope)
      script.parameters = [['keys', []], ['argv', []]]
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
  end
end
