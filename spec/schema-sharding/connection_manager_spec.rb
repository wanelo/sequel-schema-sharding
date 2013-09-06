require 'spec_helper'
require 'sequel/schema-sharding/connection_manager'

describe Sequel::SchemaSharding::ConnectionManager do
  let(:config) { Sequel::SchemaSharding::Configuration.new('boom', 'spec/fixtures/test_db_config.yml') }

  subject { Sequel::SchemaSharding::ConnectionManager.new }

  before { subject.stubs(:config).returns(config) }

  describe '#[]' do
    it 'returns a valid connection instance for the specified physical shard' do
      expect(subject['shard1']).to be_a(Sequel::Postgres::Database)
      expect(subject['shard2']).to be_a(Sequel::Postgres::Database)
    end
  end

  describe "#schema_for" do
    it "returns the schema name based on env and shard number" do
      subject.schema_for('boof', 'pickles', 3).should eq 'sequel_explosions_boof_pickles_3'
    end
  end

  describe "#default_dataset_for" do
    it "returns a dataset scoped to a configured schema" do
      # TODO ConnectionManager is dependent on global state from Sequel::SchemaSharding.config.
      #      This should be deconstructed to allow for injection of a mock config for testing.
      dataset = subject.default_dataset_for("artists")
      expect(dataset).to be_a(Sequel::Dataset)
      expect(dataset.first_source_table).to eql(:'sequel_explosions_artists_test_1__artists')
    end
  end
end
