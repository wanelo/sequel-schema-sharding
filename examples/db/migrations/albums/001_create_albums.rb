Sequel.migration do
  up do
    create_table :albums do
      Integer :artist_id, null: false
      String :name, null: false
      Date :release_date
      Time :created_at
    end
  end

  down do
    drop_table :albums
  end
end

