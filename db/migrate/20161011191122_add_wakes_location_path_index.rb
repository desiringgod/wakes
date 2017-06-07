class AddWakesLocationPathIndex < ActiveRecord::Migration[5.0]
  def change
    add_index :wakes_locations, :path
  end
end
