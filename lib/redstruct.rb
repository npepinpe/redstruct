# frozen_string_literal: true

require 'forwardable'
require 'logger'
require 'redstruct/configuration'
require 'redstruct/factory'

# Top level namespace
# TODO: Add documentation later
module Redstruct
  # @!visibility private
  class Instance
    def initialize
      @config_mutex = Mutex.new
      @logger_mutex = Mutex.new
    end

    # @return [Redstruct::Configuration] current default configuration
    def config
      return @config ||= default_config
    end

    # @param [Redstruct::Configuration] config the new configuration
    def config=(config)
      @config_mutex.synchronize { @config = config }
    end

    # The current logger; if nil, will lazily create a default logger (STDOUT, WARN)
    # @return [Logger] current logger
    def logger
      return @logger ||= default_logger
    end

    # @param [Logger] logger the new Logger compatible logger
    def logger=(logger)
      @logger_mutex.synchronize { @logger = logger }
    end

    private

    def default_logger
      logger = Logger.new(STDOUT)
      logger.level = Logger::WARN
      logger.progname = 'Redstruct'
      return logger
    end

    def default_config
      return Redstruct::Configuration.new
    end
  end

  @instance = Redstruct::Instance.new
  class << self
    extend Forwardable
    attr_reader :instance
    delegate %i[config config= logger logger=] => :instance
  end
end
