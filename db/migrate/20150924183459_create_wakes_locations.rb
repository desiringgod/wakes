class CreateWakesLocations < ActiveRecord::Migration
  def change
    create_table :wakes_locations do |t|

      t.timestamps null: false
    end
  end
end
