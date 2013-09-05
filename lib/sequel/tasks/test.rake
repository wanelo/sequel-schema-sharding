require 'sequel/sharding'

namespace :sequel do
  namespace :db do
    desc 'Create databases and shards for tests'
    task :create do
      ENV['RACK_ENV'] ||= 'test'
      Sequel::Sharding.sharding_yaml_path = "spec/fixtures/test_db_config.yml"
      Sequel::Sharding.migration_path = "spec/fixtures/db/migrate"
      manager = Sequel::Sharding::DatabaseManager.new
      manager.create_databases
      manager.create_shards
    end
  end
end
