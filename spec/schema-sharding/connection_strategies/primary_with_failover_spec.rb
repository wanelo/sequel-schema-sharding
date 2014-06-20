require 'spec_helper'
require 'sequel/schema-sharding/connection_strategies/primary_with_failover'

describe Sequel::SchemaSharding::ConnectionStrategy::PrimaryWithFailover do
  let(:db) { stub(pool: stub(failing_over?: failing_over)) }
  let(:primary) { stub }
  let(:failover) { stub }
  let(:config) { {'replicas' => [primary, failover]} }

  subject(:strategy) { Sequel::SchemaSharding::ConnectionStrategy::PrimaryWithFailover }

  describe '.choose' do
    context 'when primary is not failing' do
      let(:failing_over) { false }

      it 'returns the primary config' do
        expect(strategy.choose(db, config)).to eq(primary)
      end
    end

    context 'when primary is failing' do
      let(:failing_over) { true }

      it 'returns a random server that is not primary' do
        expect(strategy.choose(db, config)).to eq(failover)
      end
    end
  end
end
