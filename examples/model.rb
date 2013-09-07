require 'config/sharding'

class Thing < Sequel::SchemaSharding::Model('things')
  set_columns [:name, :thing1, :thing2]
  set_sharded_column :name

  # class variables used by Sequel can't easily be set via
  # pretty methods at the moment. They can be quickly overridden,
  # however.
  @require_modification = false

  def self.by_name(name)
    shard_for(name).where(name: name)
  end
end
