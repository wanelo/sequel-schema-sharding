module Sequel
  module SchemaSharding
    module ConnectionStrategy
      class Random
        def self.choose(db, config)
          choice = rand(config['replicas'].size)
          config['replicas'][choice]
        end
      end
    end
  end
end
