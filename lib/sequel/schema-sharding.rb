require 'logger'
require 'sequel'
require 'sequel/schema-sharding/version'
require 'sequel/schema-sharding/dtrace_provider'
require 'sequel/schema-sharding/configuration'
require 'sequel/schema-sharding/connection_manager'
require 'sequel/schema-sharding/database_manager'
require 'sequel/schema-sharding/ring'
require 'sequel/schema-sharding/shard_finder'
require 'sequel/schema-sharding/monkey_patching'
require 'sequel/schema-sharding/model'
require 'sequel/schema-sharding/logger_proxy'
require 'sequel/schema-sharding/connection_strategies/random'

Sequel.split_symbols = true if defined?(Sequel) && Sequel.respond_to?(:split_symbols=)

module Sequel
  module SchemaSharding
    def self.config
      @config ||= Sequel::SchemaSharding::Configuration.new(ENV['RACK_ENV'], sharding_yml_path)
    end

    def self.config=(config)
      @config = config
    end

    def self.replica_strategy
      @replica_strategy ||= Sequel::SchemaSharding::ConnectionStrategy::Random
    end

    def self.replica_strategy=(strategy)
      @replica_strategy = strategy
    end

    def self.logger
      @logger ||= Logger.new(nil)
    end

    def self.logger=(logger)
      @logger = logger
    end

    def self.connection_manager
      @connection_manager ||= ConnectionManager.new
    end

    def self.connection_manager=(connection_manager)
      @connection_manager = connection_manager
    end

    def self.sharding_yml_path
      @sharding_yml_path ||= File.expand_path('../../../config/sharding.yml', __FILE__)
    end

    def self.sharding_yml_path=(path)
      @sharding_yml_path = path
    end

    def self.migration_path
      @migration_path || raise('You must set the migration path.')
    end

    def self.migration_path=(path)
      @migration_path = path
    end

  end
end
