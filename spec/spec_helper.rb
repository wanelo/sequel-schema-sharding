ENV['RACK_ENV'] ||= 'test'

require 'simplecov'
SimpleCov.start

require 'bundler/setup'
Bundler.require 'test'

require 'sequel-schema-sharding'
require 'support/database_helper'
require 'mocha/api'

RSpec.configure do |config|
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
    Sequel::SchemaSharding.sharding_yml_path = 'spec/fixtures/test_db_config.yml'
    Sequel::SchemaSharding.migration_path = 'spec/fixtures/db/migrate'
  end

end
