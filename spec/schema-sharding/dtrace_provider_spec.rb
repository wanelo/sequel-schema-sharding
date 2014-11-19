require 'spec_helper'

describe Sequel::SchemaSharding::DTraceProvider do
  describe 'initialize' do
    it 'creates a new provider' do
      USDT::Provider.expects(:create).with(:ruby, :sequel_schema_sharding)
      Sequel::SchemaSharding::DTraceProvider.new
    end
  end

  describe 'probes' do
    let(:provider) { Sequel::SchemaSharding::DTraceProvider.new }

    describe '#replica_hash_for' do
      it 'is a probe' do
        expect(provider.replica_hash_for).to be_a USDT::Probe
      end

      it 'has :model for its function' do
        expect(provider.replica_hash_for.function).to eq(:connection_manager)
      end

      it 'has :read_only_shard_for for its name' do
        expect(provider.replica_hash_for.name).to eq(:replica_hash_for)
      end

      it 'takes a string argument' do
        expect(provider.replica_hash_for.arguments).to eq([:string])
      end
    end

    describe '#read_only_shard_for' do
      it 'is a probe' do
        expect(provider.read_only_shard_for).to be_a USDT::Probe
      end

      it 'has :model for its function' do
        expect(provider.read_only_shard_for.function).to eq(:model)
      end

      it 'has :read_only_shard_for for its name' do
        expect(provider.read_only_shard_for.name).to eq(:read_only_shard_for)
      end

      it 'takes a string argument' do
        expect(provider.read_only_shard_for.arguments).to eq([:string, :integer, :string])
      end
    end

    describe '#shard_for' do
      it 'is a probe' do
        expect(provider.shard_for).to be_a USDT::Probe
      end

      it 'has :model for its function' do
        expect(provider.shard_for.function).to eq(:model)
      end

      it 'has :read_only_shard_for for its name' do
        expect(provider.shard_for.name).to eq(:shard_for)
      end

      it 'takes a string argument' do
        expect(provider.read_only_shard_for.arguments).to eq([:string, :integer, :string])
      end
    end
  end

  describe '::provider' do
    it 'returns a DTraceProvider' do
      provider = Sequel::SchemaSharding::DTraceProvider.provider
      expect(provider).to be_a(Sequel::SchemaSharding::DTraceProvider)
    end
  end
end

