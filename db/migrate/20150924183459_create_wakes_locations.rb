class CreateWakesLocations < ActiveRecord::Migration[5.0]
  def change
    create_table :wakes_locations do |t|
      t.string :path
      t.belongs_to :wakes_resource
      t.boolean :canonical

      t.timestamps null: false
    end
  end
end
