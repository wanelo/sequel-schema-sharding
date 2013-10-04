require 'spec_helper'
require 'sequel/schema-sharding'
require 'benchmark'

describe Sequel::SchemaSharding::Finder do

  describe '.lookup' do
    it 'returns an object with a valid connection and schema' do
      result = Sequel::SchemaSharding::Finder.instance.lookup('boof', 60)
      expect(result.connection).to be_a(Sequel::Postgres::Database)
      expect(result.schema).to eq('sequel_logical_boof_01')
    end

    xit 'is fast' do
      TIMES = 150_000
      result = Benchmark.measure do
        TIMES.times do
          Sequel::SchemaSharding::Finder.instance.lookup('boof', 60)
        end
      end
      puts "performed #{TIMES} finder lookups: #{result}"
    end
  end
end
