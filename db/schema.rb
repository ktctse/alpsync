# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_05_100000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "trips", force: :cascade do |t|
    t.string "name", null: false
    t.string "resort", null: false
    t.string "region", null: false
    t.date "starts_on", null: false
    t.date "ends_on", null: false
    t.integer "party_size", default: 1, null: false
    t.string "skill_level", null: false
    t.string "languages", default: [], null: false, array: true
    t.string "looking_for", default: [], null: false, array: true
    t.string "offering", default: [], null: false, array: true
    t.string "contact_method", null: false
    t.string "contact_handle", null: false
    t.text "note"
    t.string "edit_token", null: false
    t.boolean "demo", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "avatar"
    t.index ["edit_token"], name: "index_trips_on_edit_token", unique: true
    t.index ["languages"], name: "index_trips_on_languages", using: :gin
    t.index ["region", "starts_on", "ends_on"], name: "index_trips_on_region_and_starts_on_and_ends_on"
  end
end
