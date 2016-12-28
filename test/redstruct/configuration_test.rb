# frozen_string_literal: true
require 'test_helper'

module Redstruct
  class ConfigurationTest < Redstruct::Test
    def test_initialize
      @config = Redstruct::Configuration.new
      assert_nil @config.default_connection, 'Should have no default connection initially'
      assert_nil @config.default_namespace, 'Should have no namespace initially'
    end
  end
end
