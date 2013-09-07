require 'sequel-schema-sharding'

Sequel::SchemaSharding.migration_path = File.expand_path('../db/sharding_migrations', __FILE__)
Sequel::SchemaSharding.sharding_yml_path = File.expand_path('../sharding.yml', __FILE__)
