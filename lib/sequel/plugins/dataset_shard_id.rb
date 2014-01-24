module Sequel
  module Plugins
    module DatasetShardId
      module InstanceMethods
        def shard_number
          @values[:shard_number] if @values
        end
      end

      module DatasetMethods
        def shard_number
          @shard_number
        end

        def shard_number=(id)
          @shard_number=id
        end
      end
    end
  end
end
