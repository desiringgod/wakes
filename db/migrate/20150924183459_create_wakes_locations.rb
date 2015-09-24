class CreateWakesLocations < ActiveRecord::Migration
  def change
    create_table :wakes_locations do |t|
      t.string :path
      t.belongs_to :wakes_resource

      t.timestamps null: false
    end
    
    add_index :wakes_locations, :wakes_resource_id
  end
end
