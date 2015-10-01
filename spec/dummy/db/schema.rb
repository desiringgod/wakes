# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150924183459) do

  create_table "wakes_locations", force: :cascade do |t|
    t.string   "path"
    t.integer  "wakes_resource_id"
    t.boolean  "canonical"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "wakes_locations", ["wakes_resource_id"], name: "index_wakes_locations_on_wakes_resource_id"

  create_table "wakes_resources", force: :cascade do |t|
    t.string   "label"
    t.integer  "wakeable_id"
    t.string   "wakeable_type"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "wakes_resources", ["wakeable_id", "wakeable_type"], name: "index_wakes_resources_on_wakeable_id_and_wakeable_type"

end
