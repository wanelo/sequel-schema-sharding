require 'spec_helper'
require 'sequel/schema-sharding'

describe Sequel::SchemaSharding::Ring do

  describe 'a ring of servers' do
    it 'have the continuum sorted by value' do
      shards = [1, 2, 3, 4, 5, 6, 7, 8]
      ring = Sequel::SchemaSharding::Ring.new(shards)
      previous_value = 0
      ring.continuum.each do |entry|
        expect(entry.value).to be > previous_value
        previous_value = entry.value
      end
    end
  end

  describe '#shard_for_id' do
    it 'returns a server for a given id' do
      shards = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
      ring = Sequel::SchemaSharding::Ring.new(shards)
      expect(ring.shard_for_id(3489409)).to eq(4)
    end
  end
end
