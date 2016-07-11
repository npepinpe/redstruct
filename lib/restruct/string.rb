module Restruct
  class String < Restruct::Struct
    def get
      value = nil
      @pool.with { |c| value = c.get(@key) }
      return value
    end

    def set(value)
      @pool.with { |c| c.set(@key, value) }
    end

    def getset(value)
      old_value = nil
      @pool.with { |c| c.getset(@key, value) }
      return old_value
    end
  end
end
