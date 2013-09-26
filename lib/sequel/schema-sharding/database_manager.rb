require 'sequel'
require 'sequel/schema-sharding/connection_manager'

Sequel.extension :migration

module Sequel
  module SchemaSharding
    class DatabaseManager
      def create_databases
        config.physical_shard_configs.each_pair do |name, config|
          begin
            # Need to create connection manually with specifying a database in order to create the database
            connection = Sequel.postgres(:user => config['username'],
              :password => config['password'],
              :host => config['host'])

            Sequel::SchemaSharding.logger.info "Creating #{config['database']}.."

            connection.run("CREATE DATABASE #{config['database']}")
          rescue Sequel::DatabaseError => e
            if e.message.include?('already exists')
              $stderr.puts "#{config['database']} database already exists"
            else
              raise e
            end
          ensure
            connection.disconnect
          end
        end
      end

      def drop_databases
        connection_manager.disconnect
        config.physical_shard_configs.each_pair do |name, config|
          # Need to create connection manually with specifying a database in order to create the database
          begin
            connection = Sequel.postgres(:user => config['username'],
              :password => config['password'],
              :host => config['host'])

            Sequel::SchemaSharding.logger.info "Dropping #{config['database']}.."
            connection.run("DROP DATABASE #{config['database']}")
          rescue Sequel::DatabaseError => e
            if e.message.include?('does not exist')
              $stderr.puts "#{config['database']} database doesnt exist"
            else
              raise e
            end
          ensure
            connection.disconnect
          end
        end
      end

      def create_shards
        config.table_names.each do |table_name|
          config.logical_shard_configs(table_name).each_pair do |shard_number, physical_shard|
            schema_name = connection_manager.schema_for(table_name, env, shard_number)
            Sequel::SchemaSharding.logger.info "Creating schema #{schema_name} on #{physical_shard}.."
            connection = connection_manager.master(physical_shard)

            begin
              connection.run("CREATE SCHEMA #{schema_name}")
            rescue Sequel::DatabaseError => e
              if e.message.include?('already exists')
                $stderr.puts "#{schema_name} schema already exists"
              else
                raise e
              end
            end

            connection.run("SET search_path TO #{schema_name}")

            Sequel::Migrator.run(connection, Sequel::SchemaSharding.migration_path + "/#{table_name}", :use_transactions => true)
          end
        end
      end

      def drop_shards
        config.table_names.each do |table_name|
          config.logical_shard_configs(table_name).each_pair do |shard_number, physical_shard|
            schema_name = connection_manager.schema_for(table_name, env, shard_number)
            Sequel::SchemaSharding.logger.info "Dropping schema #{schema_name} on #{physical_shard}.."
            connection = connection_manager[physical_shard]
            connection.run("DROP SCHEMA #{schema_name} CASCADE")
          end
        end
      end

      private

      def env
        config.env
      end

      def config
        Sequel::SchemaSharding.config
      end

      def connection_manager
        Sequel::SchemaSharding.connection_manager
      end
    end
  end
end
