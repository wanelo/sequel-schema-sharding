class Artist < Sequel::SchemaSharding::Model('artists')
  set_sharded_column :artist_id
  set_columns [:artist_id, :name]

  def self.by_id(artist_id)
    shard_for(artist_id).where(artist_id: artist_id)
  end
  #
  # def self.implicit_table_name
  #   'artists'
  # end

  def this
    @this ||= self.class.shard_for(self.artist_id).where(artist_id: self.artist_id)
  end

  def to_s
    "<#{self.class.name}#{self.class.object_id}:[shared_column=#{self.class.sharded_column}]{artist_id: #{artist_id}, name: #{name}}"
  end

  def inspect
    to_s
  end
end
