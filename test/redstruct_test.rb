# frozen_string_literal: true

require 'test_helper'

class RedstructTest < Redstruct::TestCase
  # Test singleton property of the config
  def test_config
    config = Redstruct.config
    assert_kind_of Redstruct::Configuration, config, 'Should return an instance of the configuration class'

    reference = Redstruct.config
    assert_equal config, reference, 'Should be a singleton object'
  end
end
