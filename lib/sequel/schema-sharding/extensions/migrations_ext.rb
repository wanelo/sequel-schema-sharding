# These are non-nasty (hopefully) extensions to the sequel
# migration code to support explicitly passing Postgres schemas.

module Sequel
  module SchemaSharding
    module Extensions
      module MigrationsExt
        def self.included(base)
          base.class_eval do
            attr_accessor :migration_current_schema
          end
        end

        def migration_schema_for_table(table)
          :"#{migration_current_schema}__#{table}"
        end
      end
    end
  end
end

module Sequel
  class Database
    include Sequel::SchemaSharding::Extensions::MigrationsExt
  end
end
