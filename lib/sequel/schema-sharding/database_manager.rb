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
              :host => config['host'],
              :port => (config['port'] || 5432))

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
              :host => config['host'],
              :port => (config['port'] || 5432))

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
          SchemaIterator.new.iterate_on(table_name) do |conn, schema_name, table_name|
            Sequel::SchemaSharding.logger.warn "Creating schema #{schema_name}.."

            begin
              conn.run("CREATE SCHEMA #{schema_name}")
            rescue Sequel::DatabaseError => e
              if e.message.include?('already exists')
                $stderr.puts "#{schema_name} schema already exists"
              else
                raise e
              end
            end

            migrator_for(conn, schema_name, table_name).run
          end
        end
      end

      def drop_shards
        config.table_names.each do |table_name|
          SchemaIterator.new.iterate_on(table_name) do |conn, schema_name, table_name|
            Sequel::SchemaSharding.logger.warn "Dropping schema #{schema_name}.."
            conn.run("DROP SCHEMA #{schema_name} CASCADE")
          end
        end
      end

      def migrate(table_name, migration_options = {})
        SchemaIterator.new.iterate_on(table_name) do |conn, schema_name, table_name|
          Sequel::SchemaSharding.logger.warn "Migrating #{table_name} in schema #{schema_name}.."
          migrator_for(conn, schema_name, table_name, migration_options).run
        end
      end

      def rollback(table_name, migration_options = {})
        SchemaIterator.new.iterate_on(table_name) do |conn, schema_name, table_name|
          Sequel::SchemaSharding.logger.warn "Rolling back #{table_name} in schema #{schema_name}.."
          migrator = migrator_for(conn, schema_name, table_name, {direction: :down}.merge(migration_options))
          # :((((((((((((((((((((((
          migrator.instance_variable_set(:@target, migrator.current - 1)
          migrator.instance_variable_set(:@direction, :down)
          migrator.run
        end
      end

      private

      def migrator_for(connection, schema, table_name, options = {})
        path = Sequel::SchemaSharding.migration_path + "/#{table_name}"
        connection.migration_current_schema = schema
        Sequel::Migrator.migrator_class(path).new(connection, path, { table: connection.migration_schema_for_table(:schema_info)}.merge(options))
      end

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

require 'sequel/schema-sharding/database_manager/schema_iterator'
