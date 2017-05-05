# frozen_string_literal: true

require 'logger'
require 'redstruct/configuration'
require 'redstruct/factory'

# TODO: Add top level documentation
module Redstruct
  class << self
    # @return [Redstruct::Configuration] current default configuration
    def config
      return @config ||= Redstruct::Configuration.new
    end

    # The current logger; if nil, will lazily create a default logger (STDOUT, WARN)
    # @return [Logger] current logger
    def logger
      return @logger ||= default_logger
    end
    attr_writer :logger

    def default_logger
      logger = Logger.new(STDOUT)
      logger.level = Logger::WARN
      logger.progname = 'Redstruct'
      return logger
    end
    private :default_logger
  end
end
