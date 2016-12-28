# frozen_string_literal: true
require 'test_helper'

class RedstructTest < Redstruct::Test
  # Test singleton property of the config
  def test_config
    config = Redstruct.config
    assert config.is_a?(Redstruct::Configuration), 'Should return an instance of the configuration class'

    reference = Redstruct.config
    assert_equal config, reference, 'Should be a singleton object'
  end
end