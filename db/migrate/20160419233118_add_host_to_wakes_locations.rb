class AddHostToWakesLocations < ActiveRecord::Migration[5.0]
  def change
    add_column :wakes_locations, :host, :string
  end
end
