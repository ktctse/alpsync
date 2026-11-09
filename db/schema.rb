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

ActiveRecord::Schema[8.1].define(version: 2026_11_09_100000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "conversations", force: :cascade do |t|
    t.bigint "trip_a_id", null: false
    t.bigint "trip_b_id", null: false
    t.datetime "trip_a_read_at"
    t.datetime "trip_b_read_at"
    t.datetime "reported_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["trip_a_id", "trip_b_id"], name: "index_conversations_on_trip_a_id_and_trip_b_id", unique: true
    t.index ["trip_a_id"], name: "index_conversations_on_trip_a_id"
    t.index ["trip_b_id"], name: "index_conversations_on_trip_b_id"
  end

  create_table "draft_usages", force: :cascade do |t|
    t.date "day", null: false
    t.integer "count", default: 0, null: false
    t.index ["day"], name: "index_draft_usages_on_day", unique: true
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.bigint "sender_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "trips", force: :cascade do |t|
    t.string "name", null: false
    t.date "starts_on", null: false
    t.date "ends_on", null: false
    t.integer "party_size", default: 1, null: false
    t.string "skill_level", null: false
    t.string "languages", default: [], null: false, array: true
    t.string "looking_for", default: [], null: false, array: true
    t.string "offering", default: [], null: false, array: true
    t.string "contact_method"
    t.string "contact_handle"
    t.text "note"
    t.string "edit_token", null: false
    t.boolean "demo", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "avatar"
    t.string "resorts", default: [], null: false, array: true
    t.string "regions", default: [], null: false, array: true
    t.index ["edit_token"], name: "index_trips_on_edit_token", unique: true
    t.index ["languages"], name: "index_trips_on_languages", using: :gin
    t.index ["regions"], name: "index_trips_on_regions", using: :gin
    t.index ["starts_on", "ends_on"], name: "index_trips_on_starts_on_and_ends_on"
  end

  create_table "unmatches", force: :cascade do |t|
    t.bigint "trip_id", null: false
    t.bigint "other_trip_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["other_trip_id"], name: "index_unmatches_on_other_trip_id"
    t.index ["trip_id", "other_trip_id"], name: "index_unmatches_on_trip_id_and_other_trip_id", unique: true
    t.index ["trip_id"], name: "index_unmatches_on_trip_id"
  end

  add_foreign_key "conversations", "trips", column: "trip_a_id", on_delete: :cascade
  add_foreign_key "conversations", "trips", column: "trip_b_id", on_delete: :cascade
  add_foreign_key "messages", "conversations", on_delete: :cascade
  add_foreign_key "messages", "trips", column: "sender_id", on_delete: :cascade
  add_foreign_key "unmatches", "trips", column: "other_trip_id", on_delete: :cascade
  add_foreign_key "unmatches", "trips", on_delete: :cascade
end
