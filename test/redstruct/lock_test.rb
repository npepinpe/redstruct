# frozen_string_literal: true

require 'test_helper'

module Redstruct
  class LockTest < Redstruct::TestCase
    def setup
      super
      @factory = create_factory
    end

    def test_initialize
      resource = 'resource'
      lock = create(resource)

      assert_equal resource, lock.resource, 'should be locking the correct resource'
      assert_nil lock.token, 'should not hold any tokens at the moment'
      assert_equal Redstruct::Lock::DEFAULT_EXPIRY, lock.expiry, 'should have the default expiry'
      assert_nil lock.timeout, 'should have the default timeout'

      expiry = rand
      timeout = rand(10)
      lock = create(timeout: timeout, expiry: expiry)
      assert_equal expiry, lock.expiry, 'should have the correct expiry'
      assert_equal timeout, lock.timeout, 'should have the correct timeout'

      lock = create(timeout: Float::INFINITY)
      assert_equal 0, lock.timeout, 'should have a timeout of 0 when given infinity'
    end

    def test_acquire
      resource = 'resource'
      lock = create(resource)

      f1 = Fiber.new do
        lock1 = create(resource)
        Fiber.yield lock1.acquire
        Fiber.yield lock1.release
        Fiber.yield lock1.acquire
      end

      f2 = Fiber.new do
        lock2 = create(resource)
        Fiber.yield lock2.acquire
        Fiber.yield lock2.acquire
        Fiber.yield lock2.release
      end

      assert f1.resume, 'should have successfully acquired the lock'
      refute f2.resume, 'should have failed to acquire the lock'
      assert f1.resume, 'should have released the lock'
      assert f2.resume, 'should have acquired the lock'
      refute f1.resume, 'should have failed to acquire the lock'
      refute lock.acquire, 'should have failed to acquire the lock'
      assert f2.resume, 'should have released the lock'
      assert lock.acquire, 'should have successfully acquired the lock'
      assert lock.release, 'should have released the lock'
    end

    # To avoid actually blocking, we simply test that the method is called
    # without actually calling it. The non-blocking tests should be
    # sufficient for the actual locking logic.
    def test_acquire_blocking
      resource = 'resource'
      lock = create(resource, expiry: 1)
      lock2 = create(resource, timeout: 1)

      tokens = lock2.instance_eval { @tokens }
      ensure_command_called(tokens, :brpop, { timeout: lock2.timeout }, allow: false).and_return(nil)

      assert lock.acquire, 'should have acquired the lock'
      refute lock2.acquire
      refute lock2.release, 'should not release something not acquired'
      assert lock.release, 'should release what was acquired'
    end

    def test_release
      lock = create
      refute lock.release, 'should not be able to release if nothing was acquired'
      assert lock.acquire, 'should acquire the lock'
      refute_nil lock.token, 'should have some token'
      assert lock.release, 'should release the acquired lock'
      assert_nil lock.token, 'should have no token once released'
    end

    def test_locked
      resource = 'resource'
      lock = create(resource)
      lock2 = create(resource)

      assert lock2.acquire, 'should be able to acquire free lock'
      refute(lock.locked { raise 'should not have been able to lock!' })
      assert lock2.release, 'should be able to release acquired lock'

      executed = false
      assert(lock.locked { executed = true }, 'should have acquired the lock')
      assert executed, 'should have executed inner block'
      assert_nil lock.token, 'should have released previous token'
      refute lock.release, 'should not be able to release lock since it was already released'
    end

    def test_delete
      lock = create(expiry: 60)
      refute lock.delete, 'should not be able to delete what does not exist'
      assert lock.acquire, 'should have acquired the lock'
      assert lock.delete, 'should delete the lock'

      lock = create(lock.resource, expiry: 60)
      assert lock.acquire, 'should be to acquire the lock again since it was deleted'
    end

    def test_nested
      lock = create
      nested = false

      lock.locked do
        lock.locked do
          nested = true
        end

        refute_nil lock.token, 'should still own the lock'
        assert lock.acquire, 'should still own the lock'
      end

      assert nested, 'should have turned on the nested flag'
    end

    private

    def create(resource = nil, **options)
      return @factory.lock(resource || SecureRandom.hex(4), **options)
    end
  end
end
