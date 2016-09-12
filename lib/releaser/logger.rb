require 'logger'

module Releaser
  class Logger < ::Logger
    TAG = '[RELEASER]'.freeze

    def info(message)
      super(TAG) { message }
    end

    def error(message)
      super(TAG) { message }
    end
  end
end
