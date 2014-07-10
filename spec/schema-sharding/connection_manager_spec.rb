require 'spec_helper'
require 'sequel/schema-sharding/connection_manager'

describe Sequel::SchemaSharding::ConnectionManager do
  let(:config) { Sequel::SchemaSharding::Configuration.new('test', 'spec/fixtures/test_db_config.yml') }

  subject { Sequel::SchemaSharding::ConnectionManager.new }

  before { subject.stubs(:config).returns(config) }
  after do
    subject.disconnect
  end

  describe '#[]' do
    it 'returns a valid connection instance for the specified physical shard' do
      expect(subject['shard1']).to be_a(Sequel::Postgres::Database)
      subject['shard1'].execute("SELECT 1")
      expect(subject['shard2']).to be_a(Sequel::Postgres::Database)
    end

    context 'read/write splitting' do
      it 'has a replica for shard2' do
        expect(subject['shard2'].servers).to include(:read_only)
        expect(subject['shard1'].servers).to_not include(:read_only)
      end

      it 'executes a select against a replica' do
        shard = subject['shard2']
        ds = shard[:"sequel_explosions_boof_pickles_3__artists"]
        shard.expects(:execute).once.with(anything, server: :read_only)
        ds.first
      end
    end
  end

  describe "#schema_for" do
    it "returns the schema name based on env and shard number" do
      expect(subject.schema_for('boof', 3)).to eq 'sequel_logical_boof_03'
    end
  end

  describe "#default_dataset_for" do
    it "returns a dataset scoped to a configured schema" do
      # TODO ConnectionManager is dependent on global state from Sequel::SchemaSharding.config.
      #      This should be deconstructed to allow for injection of a mock config for testing.
      dataset = subject.default_dataset_for("artists")
      expect(dataset).to be_a(Sequel::Dataset)
      expect(dataset.first_source_table).to match(/sequel_logical_artists_[0-9]{2}__artists/)
    end
  end
end
