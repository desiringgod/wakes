class AddWakesLocationPathIndex < ActiveRecord::Migration
  def change
    add_index :wakes_locations, :path
  end
end
