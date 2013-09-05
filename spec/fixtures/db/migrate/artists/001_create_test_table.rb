Sequel.migration do
  up do
    create_table(:artists) do
      primary_key :id
      Integer :artist_id
      String :name, :null=>false
    end
  end

  down do
    drop_table(:artists)
  end
end
