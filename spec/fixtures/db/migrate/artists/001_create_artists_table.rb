Sequel.migration do
  up do
    create_table(migration_schema_for_table(:artists)) do
      Integer :artist_id, unique: true
      String :name, :null=>false
    end
  end

  down do
    drop_table(:artists)
  end
end
