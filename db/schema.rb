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

ActiveRecord::Schema.define(version: 2018_06_27_030058) do

  create_table "accounts", force: :cascade do |t|
    t.string "name"
    t.string "origin_id"
    t.string "app_id"
    t.string "app_secret"
    t.string "token"
    t.string "aes_key"
    t.string "welcome_msg"
    t.boolean "enabled", default: false
    t.boolean "verified", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["origin_id"], name: "index_accounts_on_origin_id", unique: true
  end

  create_table "followers", force: :cascade do |t|
    t.string "user_id"
    t.string "name"
    t.string "avatar_url"
    t.string "origin"
    t.string "location"
    t.string "gender"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "messages", force: :cascade do |t|
    t.string "title"
    t.string "content"
    t.string "from"
    t.string "to"
    t.string "msg_type"
    t.string "user_id"
    t.string "origin"
    t.string "origin_id"
    t.string "url"
    t.string "media_id"
    t.string "thumb_media_id"
    t.string "format"
    t.float "longtitude"
    t.float "latitude"
    t.float "scale"
    t.datetime "send_at"
    t.string "params"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "series_batches", force: :cascade do |t|
    t.string "summary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "series_lists", force: :cascade do |t|
    t.string "sn"
    t.integer "batch_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tokens", force: :cascade do |t|
    t.string "token"
    t.string "app_id"
    t.datetime "expired"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
