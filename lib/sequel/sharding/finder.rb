require 'singleton'

module Sequel
  module Sharding
    class Finder
      class Result
        attr_reader :connection, :schema

        def initialize(connection, schema)
          @connection = connection
          @schema = schema
        end
      end

      include ::Singleton

      def lookup(id)
        shard_number = shard_for_id(id)
        physical_shard = config.logical_shard_configs[shard_number]

        conn = Sequel::Sharding.connection_manager[physical_shard]
        schema = Sequel::Sharding.connection_manager.schema_for(config.env, shard_number)

        Result.new(conn, schema)
      end

      private

      def shard_for_id(id)
        ring.shard_for_id(id)
      end

      def ring
        @ring ||= Sequel::Sharding::Ring.new(config.logical_shard_configs.keys)
      end

      def config
        Sequel::Sharding.config
      end
    end
  end
end
