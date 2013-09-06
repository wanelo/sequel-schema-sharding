require 'sequel'

module Sequel
  module SchemaSharding
    # Extensions to the Sequel model to allow logical/physical shards. Actual table models should
    # inherit this class like so:
    #
    # class Cat < Sequel::SchemaSharding::Model
    #   set_columns [:cat_id, :fur, :tongue, :whiskers] # Columns in the database need to be predefined.
    #   set_sharded_column :cat_id # Define the shard column
    #
    #   def self.by_cat_id(id)
    #     # You should always call shard_for in finders to select the correct connection.
    #     shard_for(id).where(cat_id: id)
    #   end
    # end

    def self.Model(source)
      klass = Sequel::Model(Sequel::SchemaSharding.connection_manager.default_dataset_for(source))

      klass.include(SchemaSharding::ShardedModel)

      klass
    end

    module ShardedModel

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        #protected

        # Set the column on which the current model is sharded. This is used when saving, inserting and finding
        # to decide which connection to use.
        def set_sharded_column(column)
          @sharded_column = column
        end

        # Accessor for the sharded_columns
        def sharded_column
          @sharded_column
        end

        # Return a valid Sequel::Dataset that is tied to the shard table and connection for the id and will load values
        # run by the query into the model.
        def shard_for(id)
          result = self.result_for(id)
          ds = result.connection[schema_and_table(result)]
          ds.row_proc = self
          dataset_method_modules.each { |m| ds.instance_eval { extend(m) } }
          ds.model = self
          ds
        end

        # The result of a lookup for the given id. See Sequel::SchemaSharding::Finder::Result
        def result_for(id)
          Sequel::SchemaSharding::Finder.instance.lookup(self.implicit_table_name, id)
        end

        # Construct the schema and table for use in a dataset.
        def schema_and_table(result)
          :"#{result.schema}__#{self.implicit_table_name}"
        end
      end

      # The database connection that has the logical shard.
      def db
        @db ||= finder_result.connection
      end

      # Wrapper for performing the sharding lookup based on the sharded column.
      def finder_result
        @result ||= self.class.result_for(self.send(self.class.sharded_column))
      end

      # Dataset instance based on the sharded column.
      def this_server
        @this_server ||= db[self.class.schema_and_table(finder_result)]
      end

      # Overriden to not use @dataset value from the Sequel::Model. Used internally only.
      def _insert_dataset
        this_server
      end

    end
  end
end