require 'singleton'

module Sequel
  module SchemaSharding
    ##
    # Used to manage database connections separately from database shards

    class ConnectionManager
      attr_reader :connections

      def initialize
        @connections = {}
      end

      def [](name)
        config = db_config_for(name)
        @connections[name.to_s] ||= Sequel.postgres(master_config_for(config).merge!(replica_hash_for(config)))
      end

      ##
      # Used by rake tasks that need to deterministically work against a master
      # database even when read/write splitting is configured.

      def master(name)
        @connections["master_#{name}"] ||= Sequel.postgres(master_config_for(db_config_for(name)))
      end

      def disconnect
        @connections.each_value do |conn|
          conn.disconnect
        end
        @connections = {}
      end

      ##
      # Given +table_name+ and +shard_number+, returns the name of the
      # PostgreSQL schema based on a +schema_name+ pattern defined in sharding.yml.
      # +shard_number+ is interpolated into +schema_name+ via sprintf, so
      # +schema_name+ should include a format specifier with which to interpolate
      # it (ex. %s, %02d).

      def schema_for(table_name, shard_number)
        number_of_shards = config.number_of_shards(table_name)
        pattern = config.schema_name(table_name)
        sprintf pattern, shard_number
      end

      ##
      # Given +table_name+, return a functional dataset. This is used when models
      # are loaded to read table columns and allow for data typecasting.
      # In most cases it should not be used directly in application code.

      def default_dataset_for(table_name)
        shard_number = config.logical_shard_configs(table_name).keys.first
        shard_name = config.logical_shard_configs(table_name)[shard_number]
        self[shard_name][:"#{schema_for(table_name, shard_number)}__#{table_name}"]
      end

      private

      def master_config_for(config)
        {
          :user => config['username'],
          :password => config['password'],
          :host => config['host'],
          :database => config['database'],
          :port => config['port'],
          :single_threaded => true,
          :loggers => [Sequel::SchemaSharding::LoggerProxy.new]
        }
      end

      def replica_hash_for(config)
        return {} if config['replicas'].nil?
        {
          :servers => {
            :read_only => ->(db) { config['replicas'].sample }
          }
        }
      end

      def db_config_for(name)
        config.physical_shard_configs[name]
      end

      def config
        Sequel::SchemaSharding.config
      end
    end
  end
end
