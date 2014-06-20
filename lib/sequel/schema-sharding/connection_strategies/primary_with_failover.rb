# This strategy is used for choosing a :read_only server
# to connect to.
#
# It will default to the first server in the list. In the event that
# the first server is unavailable, the remaining replicas will be
# randomly chosen from.
module Sequel
  module SchemaSharding
    module ConnectionStrategy
      class PrimaryWithFailover
        def self.choose(db, config)
          if db.pool.failing_over?
            config['replicas'][1..-1].sample
          else
            config['replicas'].first
          end
        end
      end
    end
  end
end
