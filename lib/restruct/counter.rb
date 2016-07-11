module Restruct
  class Counter < Restruct::String
    def initialize(key, pool: nil, increment: 1)
      super(key, pool: pool)
      @increment = increment
    end

    def get
      super.to_i
    end

    def set(value)
      super(value.to_i)
    end

    def increment(by: nil)
      value = 0
      by ||= @increment

      @pool.with { |c| value = c.incrby(@key, by.to_i).to_i }
      return value
    end

    def decrement(by: nil)
      value = 0
      by ||= @increment
      
      @pool.with { |c| value = c.decrby(@key, by.to_i).to_i }
      return value
    end

    def getset(value)
      return super(value.to_i).to_i
    end
  end
end
