class AddHostToWakesLocations < ActiveRecord::Migration
  def change
    add_column :wakes_locations, :host, :string
  end
end
