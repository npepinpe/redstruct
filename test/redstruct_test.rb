# frozen_string_literal: true
require 'securerandom'
require 'test_helper'

class RedstructTest < Redstruct::Test
  # Test singleton property of the config
  def test_config
    config = Redstruct.config
    assert config.is_a?(Redstruct::Configuration), 'Should return an instance of the configuration class'

    reference = Redstruct.config
    assert_equal config, reference, 'Should be a singleton object'
  end

  # Test factory caching
  def test_get
    name = SecureRandom.uuid
    assert_nil Redstruct[name], 'Should not obtain factories before their creation'

    factory = create_factory(name)
    assert_equal factory, Redstruct[name], 'Should have cached the factory after a creation'
  end

  # Test removing a factory from the cache, once deleting all its created objects, once without
  def test_delete
    name = SecureRandom.uuid
    factory = create_factory(name)
    assert_equal factory, Redstruct[name], 'Should be the factory from the cache, otherwise the test is pointless'

    # no point testing the clear option if nothing is in the DB
    token = SecureRandom.uuid
    object = factory.string('test')
    object.set(token)

    Redstruct.delete(name)
    assert_nil Redstruct[name], 'Should have removed the factory from the cache'
    assert_equal token, object.get, 'Object should still be present'

    # we need to recache the factory, and the only public way to do so is to recreate it
    factory = create_factory(name)
    object = factory.string('test')
    assert_equal token, object.get, 'Object should be the same as before'
    Redstruct.delete(name, clear: true)

    assert_nil object.get, 'Object should have been removed'
  end

  # Test creating a factory caches it if a name is given
  def test_make
    name = SecureRandom.uuid
    factory = Redstruct.make(name: name)
    assert factory.is_a?(Redstruct::Factory), 'Should have successfully created the factory'
    assert_equal factory, Redstruct[name], 'Should have cached the factory'

    # Manually delete the factory since we're not using the helper
    Redstruct.delete(name)
  end
end
