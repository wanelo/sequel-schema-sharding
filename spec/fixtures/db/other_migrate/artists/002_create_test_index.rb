Sequel.migration do
  up do
    add_index(migration_schema_for_table(:artists), :name, concurrently: true)
  end

  down do
    drop_index(migration_schema_for_table(:artists), :name, concurrently: true)
  end
end
