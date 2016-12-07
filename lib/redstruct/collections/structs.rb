# frozen_string_literal: true
module Redstruct
  module Collections
    class Structs < Redstruct::Collections::Base
      # Deletes all the keys in the collection
      def delete
        self.connection.del(*@keys)
      end
    end
  end
end
