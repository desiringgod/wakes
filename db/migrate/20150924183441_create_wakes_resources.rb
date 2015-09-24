class CreateWakesResources < ActiveRecord::Migration
  def change
    create_table :wakes_resources do |t|

      t.timestamps null: false
    end
  end
end
