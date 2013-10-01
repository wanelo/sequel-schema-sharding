require 'spec_helper'
require 'sequel/schema-sharding'

describe Sequel::SchemaSharding::Finder do

  describe '.lookup' do
    it 'returns an object with a valid connection and schema' do
      result = Sequel::SchemaSharding::Finder.instance.lookup('boof', 60)
      expect(result.connection).to be_a(Sequel::Postgres::Database)
      expect(result.schema).to eq('sequel_logical_boof_02')
    end
  end
end
