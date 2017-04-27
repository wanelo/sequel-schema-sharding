require 'spec_helper'
require 'sequel/schema-sharding'
require 'benchmark'

describe Sequel::SchemaSharding::ShardFinder do

  describe '.lookup' do
    it 'returns an object with a valid connection and schema' do
      result = Sequel::SchemaSharding::ShardFinder.instance.lookup('boof', 60)
      expect(result.connection).to be_a(Sequel::Postgres::Database)
      expect(result.schema).to eq('sequel_logical_boof_01')
      expect(result.shard_number).to eq(1)
    end

    context 'performance' do
      include RSpec::Benchmark::Matchers
      it 'is fast' do
        expect do
          Sequel::SchemaSharding::ShardFinder.instance.lookup('boof', 60)
        end.to perform_at_least(100000, time: 0.3, warmup: 0.1)
      end
    end
  end
end
