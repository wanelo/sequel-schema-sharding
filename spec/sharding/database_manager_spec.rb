require 'spec_helper'
require 'sequel/sharding'

describe Sequel::Sharding::DatabaseManager, type: :manager, sharded: true do

  let(:config) { Sequel::Sharding::Configuration.new('boom', 'spec/fixtures/test_db_config.yml') }

  after do
    Sequel::Sharding.connection_manager.disconnect
  end

  around do |ex|
    Sequel::Sharding.stubs(:config).returns(config)

    @manager = Sequel::Sharding::DatabaseManager.new
    @manager.send(:connection_manager).disconnect
    DatabaseHelper.disconnect

    DatabaseHelper.drop_db('sequel_boom_shard1')
    DatabaseHelper.drop_db('sequel_boom_shard2')

    ex.call
  end

  describe '#create_database' do
    context 'database does not exist' do
      it 'creates the database for the current environment' do
        expect(DatabaseHelper.db_exists?('sequel_boom_shard1')).to be_false
        expect(DatabaseHelper.db_exists?('sequel_boom_shard2')).to be_false
        @manager.create_databases
        expect(DatabaseHelper.db_exists?('sequel_boom_shard1')).to be_true
        expect(DatabaseHelper.db_exists?('sequel_boom_shard2')).to be_true
      end
    end

    context 'database exists' do

      before(:each) do
        @manager.create_databases
      end

      it 'outputs message to stderr' do
        expect(DatabaseHelper.db_exists?('sequel_boom_shard1')).to be_true
        expect(DatabaseHelper.db_exists?('sequel_boom_shard2')).to be_true
        $stderr.expects(:puts).with(regexp_matches(/already exists/)).twice
        @manager.create_databases
        expect(DatabaseHelper.db_exists?('sequel_boom_shard1')).to be_true
        expect(DatabaseHelper.db_exists?('sequel_boom_shard2')).to be_true
      end
    end
  end

  describe '#drop_databases' do
    context 'databases exist' do
      it 'drops the database for the current environment' do
        expect(DatabaseHelper.db_exists?('sequel_boom_shard1')).to be_false
        expect(DatabaseHelper.db_exists?('sequel_boom_shard2')).to be_false

        @manager.create_databases
        expect(DatabaseHelper.db_exists?('sequel_boom_shard1')).to be_true
        expect(DatabaseHelper.db_exists?('sequel_boom_shard2')).to be_true

        @manager.drop_databases
        expect(DatabaseHelper.db_exists?('sequel_boom_shard1')).to be_false
        expect(DatabaseHelper.db_exists?('sequel_boom_shard2')).to be_false
      end
    end

    context 'databases dont exist' do
      it 'raises an error' do
        expect(DatabaseHelper.db_exists?('sequel_boom_shard1')).to be_false
        expect(DatabaseHelper.db_exists?('sequel_boom_shard2')).to be_false

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
        expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_boof_boom_1')).to be_false
        expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_artists_boom_1')).to be_false
        @manager.create_shards
        expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_boof_boom_1')).to be_true
        expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_artists_boom_1')).to be_true
      end

      context 'shards already exist' do
        it 'prints that shards already exist' do
          expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_boof_boom_1')).to be_false
          expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_artists_boom_1')).to be_false
          @manager.create_shards
          expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_boof_boom_1')).to be_true
          expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_artists_boom_1')).to be_true

          $stderr.expects(:puts).with(regexp_matches(/already exists/)).at_least_once
          @manager.create_shards
        end
      end
    end

    describe '#drop_schemas' do
      context 'schemas exist' do
        it 'drops the schemas' do
          expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_boof_boom_1')).to be_false
          expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_artists_boom_1')).to be_false
          @manager.create_shards
          expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_boof_boom_1')).to be_true
          expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_artists_boom_1')).to be_true
          @manager.drop_shards
          expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_boof_boom_1')).to be_false
          expect(DatabaseHelper.schema_exists?('shard1', 'sequel_explosions_artists_boom_1')).to be_false
        end
      end
    end
  end
end
