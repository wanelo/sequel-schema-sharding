require 'spec_helper'
require 'sequel/schema-sharding'

describe Sequel::SchemaSharding::DatabaseManager, type: :manager, sharded: true do

  let(:config) { Sequel::SchemaSharding::Configuration.new('boom', 'spec/fixtures/test_db_config.yml') }

  after do
    Sequel::SchemaSharding.connection_manager.disconnect
  end

  around do |ex|
    Sequel::SchemaSharding.stubs(:config).returns(config)

    @manager = Sequel::SchemaSharding::DatabaseManager.new
    @manager.send(:connection_manager).disconnect
    DatabaseHelper.disconnect

    DatabaseHelper.drop_db('sequel_boom_shard1')
    DatabaseHelper.drop_db('sequel_boom_shard2')

    ex.call
  end

  describe '#create_database' do
    context 'database does not exist' do
      it 'creates the database for the current environment' do
        expect(DatabaseHelper.db_exists?('sequel_boom_shard1')).to be false
        expect(DatabaseHelper.db_exists?('sequel_boom_shard2')).to be false
        @manager.create_databases
        expect(DatabaseHelper.db_exists?('sequel_boom_shard1')).to be true
        expect(DatabaseHelper.db_exists?('sequel_boom_shard2')).to be true
      end
    end

    context 'database exists' do

      before(:each) do
        @manager.create_databases
      end

      it 'outputs message to stderr' do
        expect(DatabaseHelper.db_exists?('sequel_boom_shard1')).to be true
        expect(DatabaseHelper.db_exists?('sequel_boom_shard2')).to be true
        $stderr.expects(:puts).with(regexp_matches(/already exists/)).twice
        @manager.create_databases
        expect(DatabaseHelper.db_exists?('sequel_boom_shard1')).to be true
        expect(DatabaseHelper.db_exists?('sequel_boom_shard2')).to be true
      end
    end
  end

  describe '#drop_databases' do
    context 'databases exist' do
      it 'drops the database for the current environment' do
        expect(DatabaseHelper.db_exists?('sequel_boom_shard1')).to be false
        expect(DatabaseHelper.db_exists?('sequel_boom_shard2')).to be false

        @manager.create_databases
        expect(DatabaseHelper.db_exists?('sequel_boom_shard1')).to be true
        expect(DatabaseHelper.db_exists?('sequel_boom_shard2')).to be true

        @manager.drop_databases
        expect(DatabaseHelper.db_exists?('sequel_boom_shard1')).to be false
        expect(DatabaseHelper.db_exists?('sequel_boom_shard2')).to be false
      end
    end

    context 'databases dont exist' do
      it 'raises an error' do
        expect(DatabaseHelper.db_exists?('sequel_boom_shard1')).to be false
        expect(DatabaseHelper.db_exists?('sequel_boom_shard2')).to be false

        $stderr.expects(:puts).with(regexp_matches(/database doesnt exist/)).times(2)

        @manager.drop_databases
      end
    end
  end

  describe 'logical shards' do
    before(:each) do
      @manager.create_databases
    end

    describe '#create_shards' do
      it 'creates the database structure' do
        expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_boof_01')).to be false
        expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_artists_01')).to be false
        @manager.create_shards
        expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_boof_01')).to be true
        expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_artists_01')).to be true
      end

      context 'shards already exist' do
        it 'prints that shards already exist' do
          expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_boof_01')).to be false
          expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_artists_01')).to be false
          @manager.create_shards
          expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_boof_01')).to be true
          expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_artists_01')).to be true

          $stderr.expects(:puts).with(regexp_matches(/already exists/)).at_least_once
          @manager.create_shards
        end
      end
    end

    describe '#drop_schemas' do
      context 'schemas exist' do
        it 'drops the schemas' do
          expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_boof_01')).to be false
          expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_artists_01')).to be false
          @manager.create_shards
          expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_boof_01')).to be true
          expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_artists_01')).to be true
          @manager.drop_shards
          expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_boof_01')).to be false
          expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_artists_01')).to be false
        end
      end
    end
  end

  describe 'schema migrations' do
    before(:each) do
      @manager.create_databases
      @manager.create_shards
    end

    before do
      Sequel::SchemaSharding.migration_path = "spec/fixtures/db/other_migrate"
    end

    after do
      Sequel::SchemaSharding.migration_path = "spec/fixtures/db/migrate"
    end

    describe '#migrate' do
      it 'runs migrations against the table on all schemas' do
        expect(DatabaseHelper.index_count('shard1', 'sequel_explosions_artists_01', 'artists', 'name')).to eq(0)
        @manager.migrate('artists', allow_missing_migration_files: true, use_transactions: false, current: 1)
        expect(DatabaseHelper.index_count('shard1', 'sequel_explosions_artists_01', 'artists', 'name')).to eq(1)
      end
    end

    describe '#rollback' do
      it 'runs migrations against the table on all schemas' do
        expect(DatabaseHelper.index_count('shard1', 'sequel_explosions_artists_01', 'artists', 'name')).to eq(0)
        @manager.migrate('artists', allow_missing_migration_files: true, use_transactions: false, current: 1)
        expect(DatabaseHelper.index_count('shard1', 'sequel_explosions_artists_01', 'artists', 'name')).to eq(1)
        @manager.rollback('artists', allow_missing_migration_files: true, use_transactions: false, current: 1)
        expect(DatabaseHelper.index_count('shard1', 'sequel_explosions_artists_01', 'artists', 'name')).to eq(0)
      end
    end
  end
end
