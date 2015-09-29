class CreateWakesResources < ActiveRecord::Migration
  def change
    create_table :wakes_resources do |t|
      t.string :label
      t.references :wakeable, :polymorphic => true

      t.timestamps null: false
    end

    add_index :wakes_resources, [:wakeable_id, :wakeable_type]
  end
end
