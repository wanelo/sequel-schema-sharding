class Sequel::SchemaSharding::DatabaseManager::SchemaIterator
  def iterate_on(table_name, &block)
    config.logical_shard_configs(table_name).each_pair do |shard_number, physical_shard|
      schema_name = connection_manager.schema_for(table_name, shard_number)
      connection = connection_manager.master(physical_shard)

      yield connection, schema_name, table_name
    end
  end

  private

  def config
    Sequel::SchemaSharding.config
  end

  def connection_manager
    Sequel::SchemaSharding.connection_manager
  end
end
