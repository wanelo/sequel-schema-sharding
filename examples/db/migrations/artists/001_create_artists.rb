Sequel.migration do
  up do
    create_table :artists do
      Integer :id, null: false
      String :name, null: false
      Time :created_at
    end
  end

  down do
    drop_table :artists
  end
end


