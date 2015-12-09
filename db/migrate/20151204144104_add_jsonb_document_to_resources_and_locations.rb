class AddJsonbDocumentToResourcesAndLocations < ActiveRecord::Migration
  def change
    add_column :wakes_resources, :document, :jsonb
    add_column :wakes_locations, :document, :jsonb

    add_index :wakes_resources, :document, :using => :gin
    add_index :wakes_locations, :document, :using => :gin
  end
end
