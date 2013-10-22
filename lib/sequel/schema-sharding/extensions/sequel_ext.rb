module Sequel
  module SchemaSharding
    module Extensions
      module SequelExt
        module ClassMethods
          def db
            return @db if @db
          end
        end
      end
    end
  end
end

Sequel::Model.plugin Sequel::SchemaSharding::Extensions::SequelExt
Sequel::Model.plugin :validation_helpers
