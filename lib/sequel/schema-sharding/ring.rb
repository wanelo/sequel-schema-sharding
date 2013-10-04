require 'digest/sha1'
require 'zlib'

module Sequel
  module SchemaSharding
    # This class is responsible for mapping IDs into shards, using
    # Ketama consistent hashing algorithm, which makes it easier to
    # rehash in the future, should the number of shards increase.
    # For more information see http://en.wikipedia.org/wiki/Consistent_hashing
    # This implementation is borrowed from Dali memcached library.
    class Ring
      POINTS_PER_SERVER = 1
      PRODUCTION_SHARDS = 8192

      attr_accessor :shards, :continuum

      def initialize(shards)
        @number_of_shards = shards.size
        if ENV['RACK_ENV'] == "production"
          raise "Expecting production shards to be #{PRODUCTION_SHARDS}, got #{@number_of_shards}" \
            if @number_of_shards != PRODUCTION_SHARDS
        end
      end

      def shard_for_id(id)
        id = id.to_i
        raise "id is passed as zero" if id == 0
        id % @number_of_shards + 1
      end
    end
  end
end
