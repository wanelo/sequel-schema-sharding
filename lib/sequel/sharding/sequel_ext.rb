module Sequel
  module Sharding
    module SequelExt
      module ClassMethods
        def db
          return @db if @db
        end
      end
    end
  end
end

Sequel::Model.plugin Sequel::Sharding::SequelExt
Sequel::Model.plugin :validation_helpers
