require 'spec_helper'

describe Sequel::SchemaSharding, 'Model' do

  before do
    require 'support/artist'
  end

  describe 'creating records and reading them from database' do
    let(:artist_id) { 14 }
    let(:another_artist_id) { 15 }

    before do
      Artist.shard_for(artist_id).truncate
    end

    let(:artist_name) { 'Paul' }
    let(:artist_hash) { { artist_id: artist_id, name: artist_name } }
    let(:read_back_artist) { Artist.by_id(artist_id).first }
    let(:artist) { Artist.create(artist_hash) }

    it 'can create a valid record' do
      expect(artist.artist_id).to eq(artist_id)
      expect(artist.name).to eq(artist_name)
    end

    context 'with an artist created' do
      before do
        expect(artist).to_not be_nil
      end

      it 'can read back created record' do
        expect(read_back_artist).to be_a(Artist)
        expect(read_back_artist.name).to eql('Paul')
        read_back_artist.destroy
        read_back_artist = Artist.where(artist_id: artist_id).first
        expect(read_back_artist).to be_nil
      end

      it 'includes shard number on model instances' do
        shard_number = Artist.shard_for(artist_id).shard_number
        expect(read_back_artist.shard_number).to eq(shard_number)
      end

      it 'sets different shard number for another ID' do
        shard_number = Artist.shard_for(artist_id).shard_number
        another_shard_number = Artist.shard_for(another_artist_id).shard_number
        expect(another_shard_number).not_to eq(shard_number)
      end
    end

    describe '#shard_for' do
      let(:dataset) { Artist.shard_for(2356) }

      it 'returns a dataset' do
        expect(dataset).to be_a(Sequel::Dataset)
      end

      it 'connects to the shard for the given id' do
        expect(dataset.db.opts[:database]).to eq('sequel_test_shard2')
        expect(dataset.first_source).to eq(:sequel_logical_artists_17__artists)
      end

      it 'includes shard_number on dataset' do
        expect(dataset.shard_number).to eq(17)
      end
    end

    describe '#read_only_shard_for' do
      let(:dataset) { Artist.read_only_shard_for(2356) }

      it 'returns a dataset' do
        expect(dataset).to be_a(Sequel::Dataset)
      end

      it 'connects to the shard for the given id' do
        expect(dataset.db.opts[:database]).to eq('sequel_test_shard2')
        expect(dataset.first_source).to eq(:sequel_logical_artists_17__artists)
      end

      it 'is read_only' do
        expect(dataset.opts[:server]).to eq(:read_only)
      end
    end

  end
end

