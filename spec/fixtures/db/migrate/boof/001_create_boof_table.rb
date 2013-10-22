Sequel.migration do
  up do
    create_table(migration_schema_for_table(:boofs)) do
      primary_key :id
      String :name, :null=>false
    end
  end

  down do
    drop_table(:boofs)
  end
end
