module Sequel
  module SchemaSharding
    module SequelExt
      module ClassMethods
        def db
          return @db if @db
        end
      end
    end
  end
end

Sequel::Model.plugin Sequel::SchemaSharding::SequelExt
Sequel::Model.plugin :validation_helpers
