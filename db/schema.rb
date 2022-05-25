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

ActiveRecord::Schema[7.0].define(version: 2022_05_24_033456) do
  create_table "active_readings", force: :cascade do |t|
    t.integer "message_cursor_id"
    t.integer "message_id"
    t.datetime "expires_at", precision: nil
    t.boolean "died", default: false
    t.integer "read_count", default: 0
    t.integer "max_reads"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_cursor_id", "expires_at"], name: "index_active_readings_on_message_cursor_id_and_expires_at"
    t.index ["message_cursor_id", "message_id"], name: "index_active_readings_on_message_cursor_id_and_message_id", unique: true
    t.index ["message_cursor_id"], name: "index_active_readings_on_message_cursor_id"
    t.index ["message_id"], name: "index_active_readings_on_message_id"
  end

  create_table "channels", force: :cascade do |t|
    t.string "name"
    t.string "owner_uid"
    t.boolean "expire_messages", default: false
    t.integer "force_message_expiration_time"
    t.integer "default_max_reads"
    t.integer "default_read_timeout"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_channels_on_name", unique: true
    t.index ["owner_uid"], name: "index_channels_on_owner_uid"
  end

  create_table "message_cursors", force: :cascade do |t|
    t.string "originator_uid"
    t.integer "channel_id"
    t.integer "last_message_id"
    t.integer "default_max_reads"
    t.integer "default_read_timeout"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["channel_id"], name: "index_message_cursors_on_channel_id"
    t.index ["last_message_id"], name: "index_message_cursors_on_last_message_id"
  end

  create_table "message_metadata", force: :cascade do |t|
    t.integer "message_id"
    t.string "key"
    t.string "value"
    t.index ["message_id"], name: "index_message_metadata_on_message_id"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "channel_id"
    t.string "message_origination_reference"
    t.string "message_reference"
    t.string "publisher_uid"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["channel_id", "id"], name: "index_messages_on_channel_id_and_id"
    t.index ["channel_id", "message_origination_reference"], name: "index_messages_on_channel_id_and_message_origination_reference", unique: true
    t.index ["channel_id"], name: "index_messages_on_channel_id"
    t.index ["message_reference"], name: "index_messages_on_message_reference", unique: true
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer "channel_id"
    t.integer "default_message_cursor_id"
    t.string "name"
    t.string "subscriber_uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["channel_id", "name"], name: "index_subscriptions_on_channel_id_and_name", unique: true
    t.index ["channel_id"], name: "index_subscriptions_on_channel_id"
    t.index ["default_message_cursor_id"], name: "index_subscriptions_on_default_message_cursor_id"
  end

end
