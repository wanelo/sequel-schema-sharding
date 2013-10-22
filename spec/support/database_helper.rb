require 'sequel'

class DatabaseHelper
  def self.db
    @db = Sequel.postgres(user: 'postgres', password: 'alkfjasdlfj', host: 'localhost')
  end

  def self.disconnect
    db.disconnect
  end

  def self.drop_db(database)
    if db_exists?("#{database}")
      self.disconnect

      db.run("DROP DATABASE #{database}")
    end
  end

  def self.db_exists?(database)
    dbs.include?(database)
  end

  def self.dbs
    db.fetch('SELECT datname FROM pg_database WHERE datistemplate = false;').all.map { |d| d[:datname] }
  end

  def self.schema_exists?(database, schema)
    schemas(database).include?(schema)
  end

  def self.index_count(database, schema, table, column)
    Sequel::SchemaSharding.connection_manager[database]
                          .fetch("select * from pg_catalog.pg_indexes where tablename = '#{table}' and schemaname = '#{schema}' and indexdef LIKE '%#{column}%'")
                          .count
  end

  def self.schemas(database)
    Sequel::SchemaSharding.connection_manager[database].fetch('select nspname from pg_catalog.pg_namespace;').all.map { |d| d[:nspname] }
  end
end
