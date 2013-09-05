require 'spec_helper'
require 'sequel/sharding'

describe Sequel::Sharding::Finder do

  describe '.lookup' do
    it 'returns an object with a valid connection and schema' do
      result = Sequel::Sharding::Finder.instance.lookup('boof', 60)
      expect(result.connection).to be_a(Sequel::Postgres::Database)
      expect(result.schema).to eq('sequel_logical_boof_test_2')
    end
  end
end
