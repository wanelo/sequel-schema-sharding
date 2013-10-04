require 'spec_helper'
require 'sequel/schema-sharding'

describe Sequel::SchemaSharding::Ring do
  describe '#shard_for_id' do
    it 'returns a server for a given id' do
      @shards = 16
      shards = (1..@shards).to_a
      ring = Sequel::SchemaSharding::Ring.new(shards)

      hash = {}
      (1..10_000).to_a.each do |i|
        shard = ring.shard_for_id(i)
        hash[shard] ||= 0;
        hash[shard] += 1;
      end

      expect(hash.size).to eq(@shards)
      hash.values.each do |value|
        expect(value).to eq(10_000 / @shards)
      end
    end
  end

  describe "#initialize" do
    context "production" do
      it "raises an exception if the number of shards is not 8192" do
        env = ENV['RACK_ENV']
        ENV['RACK_ENV'] = 'production'

        expect do
          Sequel::SchemaSharding::Ring.new((1..10).to_a)
        end.to raise_error(RuntimeError)

        ENV['RACK_ENV'] = env
      end
    end
  end
end
