require "sequel/sharding/version"
require 'sequel/sharding/configuration'
require 'sequel/sharding/connection_manager'
require 'sequel/sharding/database_manager'
require 'sequel/sharding/ring'
require 'sequel/sharding/finder'
require 'sequel/sharding/sequel_ext'
require 'sequel/sharding/model'
require 'logger'

module Sequel
  module Sharding
    def self.config
      @config ||= Sequel::Sharding::Configuration.new(ENV['RACK_ENV'], sharding_yml_path)
    end

    def self.config=(config)
      @config = config
    end

    def self.logger
      @logger ||= Logger.new($stdout)
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

    def self.sharding_yaml_path=(path)
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
