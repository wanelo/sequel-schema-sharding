require 'singleton'

module Sequel
  module SchemaSharding
    class Finder
      class Result
        attr_reader :connection, :schema

        def initialize(connection, schema)
          @connection = connection
          @schema = schema
        end
      end

      include ::Singleton

      def lookup(table_name, id)
        shard_number = shard_for_id(table_name, id)
        physical_shard = config.logical_shard_configs(table_name)[shard_number]

        conn = Sequel::SchemaSharding.connection_manager[physical_shard]
        schema = Sequel::SchemaSharding.connection_manager.schema_for(table_name, shard_number)

        Result.new(conn, schema)
      end

      private

      def shard_for_id(table_name, id)
        ring(table_name).shard_for_id(id)
      end

      def ring(table_name)
        @rings ||= {}
        @rings[table_name] ||= Sequel::SchemaSharding::Ring.new(config.logical_shard_configs(table_name).keys)
      end

      def config
        Sequel::SchemaSharding.config
      end
    end
  end
end
