module Sequel
  module Postgres
    class Dataset
      alias_method :adapter_fetch_rows, :fetch_rows

      def fetch_rows(sql, &block)
        adapter_fetch_rows(sql) do |r|
          if self.respond_to?(:shard_number)
            r[:shard_number] = self.shard_number
          end
          block.call r
        end
      end
    end
  end
end
