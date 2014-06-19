# This strategy is used for choosing a :read_only server
# to connect to.
#
# A random server will be chosen from the replica list
# for this physical shard.
module Sequel
  module SchemaSharding
    module ConnectionStrategy
      class Random
        def self.choose(db, config)
          config['replicas'].sample
        end
      end
    end
  end
end
