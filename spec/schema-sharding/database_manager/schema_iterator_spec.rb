require 'spec_helper'

describe Sequel::SchemaSharding::DatabaseManager::SchemaIterator do
  subject { Sequel::SchemaSharding::DatabaseManager::SchemaIterator.new }

  describe '#iterate_on' do
    let(:expector) { stub }

    it 'calls the given block with the connection, schema, and table name for each shard' do
      expector.expects(:boom).times(20).with(kind_of(Sequel::Database), kind_of(String), 'artists')

      subject.iterate_on('artists') do |*args|
        expector.boom(*args)
      end
    end
  end
end
