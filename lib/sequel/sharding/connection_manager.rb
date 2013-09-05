require 'singleton'

module Sequel
  module Sharding
    class ConnectionManager
      attr_reader :connections

      def initialize
        @connections = {}
      end

      def [](name)
        config = db_config_for(name)
        @connections[name.to_s] ||= Sequel.postgres(:user => config['username'],
                                                    :password => config['password'],
                                                    :host => config['host'],
                                                    :database => config['database'])
      end

      def disconnect
        @connections.each_value do |conn|
          conn.disconnect
        end
        @connections = {}
      end

      def schema_for(table_name, environment, shard_number)
        config.schema_name(table_name).gsub('%e', environment).gsub('%s', shard_number.to_s)
      end

      def default_dataset_for(table_name)
        shard_number = config.logical_shard_configs(table_name).keys.first
        shard_name = config.logical_shard_configs(table_name)[shard_number]
        self[shard_name][:"#{schema_for(table_name, ENV['RACK_ENV'], shard_number)}__#{table_name}"]
      end

      private

      def db_config_for(name)
        config.physical_shard_configs[name]
      end

      def config
        Sequel::Sharding.config
      end
    end
  end
end
