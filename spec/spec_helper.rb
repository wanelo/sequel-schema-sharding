ENV['RACK_ENV'] ||= 'test'

require 'bundler/setup'
Bundler.require 'test'

require 'sequel-schema-sharding'
require 'support/database_helper'
require 'mocha/api'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.alias_example_to :fit, focus: true
  config.mock_framework = :mocha


  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.before :all do |ex|
    Sequel::SchemaSharding.logger = Logger.new(StringIO.new)
    Sequel::SchemaSharding.sharding_yml_path = "spec/fixtures/test_db_config.yml"
    Sequel::SchemaSharding.migration_path = "spec/fixtures/db/migrate"
  end

  config.around :each do |ex|
    #Sequel::SchemaSharding.config = Sequel::SchemaSharding::Configuration.new('boom', 'spec/fixtures/test_db_config.yml')

    # Start transactions in each connection to the physical shards
    connections = Sequel::SchemaSharding.config.physical_shard_configs.map do |shard_config|
      Sequel::SchemaSharding.connection_manager[shard_config[0]]
    end

    start_transaction_proc = Proc.new do |connections|
      if connections.length == 0
        ex.run
      else
        connections[0].transaction do
          connections.shift
          start_transaction_proc.call(connections)
          raise Sequel::Rollback
        end
      end
    end

    start_transaction_proc.call(connections)
  end

end
