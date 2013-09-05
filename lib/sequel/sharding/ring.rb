require 'digest/sha1'
require 'zlib'

module Sequel
  module Sharding
    class Ring
      POINTS_PER_SERVER = 1

      attr_accessor :shards, :continuum

      def initialize(shards)
        @shards = shards
        @continuum = nil
        if shards.size > 1
          continuum = []
          shards.each do |shard|
            hash = Digest::SHA1.hexdigest("#{shard}")
            value = Integer("0x#{hash[0..7]}")
            continuum << Entry.new(value, shard)
          end
          @continuum = continuum.sort { |a, b| a.value <=> b.value }
        end
      end

      def shard_for_id(id)
        if @continuum
          hkey = hash_for(id)
          entryidx = binary_search(@continuum, hkey)
          return @continuum[entryidx].server
        else
          server = @servers.first
          return server if server
        end

        raise StandardError, "No server available"
      end

      private

      def hash_for(key)
        Zlib.crc32(key.to_s)
      end

      def entry_count
        ((shards.size * POINTS_PER_SERVER)).floor
      end

      # Native extension to perform the binary search within the continuum
      # space.  Fallback to a pure Ruby version if the compilation doesn't work.
      # optional for performance and only necessary if you are using multiple
      # memcached servers.
      begin
        require 'inline'
        inline do |builder|
          builder.c <<-EOM
              int binary_search(VALUE ary, unsigned int r) {
                  long upper = RARRAY_LEN(ary) - 1;
                  long lower = 0;
                  long idx = 0;
                  ID value = rb_intern("value");
                  VALUE continuumValue;
                  unsigned int l;

                  while (lower <= upper) {
                      idx = (lower + upper) / 2;

                      continuumValue = rb_funcall(RARRAY_PTR(ary)[idx], value, 0);
                      l = NUM2UINT(continuumValue);
                      if (l == r) {
                          return idx;
                      }
                      else if (l > r) {
                          upper = idx - 1;
                      }
                      else {
                          lower = idx + 1;
                      }
                  }
                  return upper;
              }
          EOM
        end
      rescue LoadError
        # Find the closest index in the Ring with value <= the given value
        def binary_search(ary, value)
          upper = ary.size - 1
          lower = 0
          idx = 0

          while (lower <= upper) do
            idx = (lower + upper) / 2
            comp = ary[idx].value <=> value

            if comp == 0
              return idx
            elsif comp > 0
              upper = idx - 1
            else
              lower = idx + 1
            end
          end
          return upper
        end
      end

      class Entry
        attr_reader :value
        attr_reader :server

        def initialize(val, srv)
          @value = val
          @server = srv
        end
      end

    end
  end
end
