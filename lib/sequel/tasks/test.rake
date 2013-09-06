require 'sequel/schema-sharding'

namespace :sequel do
  namespace :db do
    desc 'Create databases and shards for tests'
    task :create do
      ENV['RACK_ENV'] ||= 'test'
      Sequel::SchemaSharding.sharding_yml_path = "spec/fixtures/test_db_config.yml"
      Sequel::SchemaSharding.migration_path = "spec/fixtures/db/migrate"
      manager = Sequel::SchemaSharding::DatabaseManager.new
      manager.create_databases
      manager.create_shards
    end

    desc 'Create databases and shards for tests'
    task :drop do
      ENV['RACK_ENV'] ||= 'test'
      Sequel::SchemaSharding.sharding_yml_path = "spec/fixtures/test_db_config.yml"
      Sequel::SchemaSharding.migration_path = "spec/fixtures/db/migrate"
      manager = Sequel::SchemaSharding::DatabaseManager.new
      manager.drop_databases
    end
  end
end
