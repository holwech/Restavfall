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

ActiveRecord::Schema.define(version: 20150821102754) do

  create_table "events", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "url",        limit: 255
    t.datetime "time"
    t.string   "fbpageID",   limit: 255
    t.string   "fbeventID",  limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "img",        limit: 255
  end

  create_table "results", force: :cascade do |t|
    t.string   "userName",   limit: 255
    t.string   "userImg",    limit: 255
    t.string   "friendName", limit: 255
    t.string   "friendImg",  limit: 255
    t.integer  "eventId",    limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255,   null: false
    t.text     "data",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", unique: true, using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "uke_events", force: :cascade do |t|
    t.string   "event_type", limit: 255
    t.string   "title",      limit: 255
    t.text     "text",       limit: 65535
    t.string   "image",      limit: 255
    t.string   "age_limit",  limit: 255
    t.string   "slug",       limit: 255
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "uke_showings", force: :cascade do |t|
    t.integer  "uke_event_id",      limit: 4
    t.string   "status",            limit: 255
    t.boolean  "tickets_available", limit: 1
    t.integer  "price",             limit: 4
    t.boolean  "sale_open",         limit: 1
    t.boolean  "free",              limit: 1
    t.boolean  "canceled",          limit: 1
    t.datetime "date"
    t.datetime "sale_to"
    t.datetime "sale_from"
    t.string   "title",             limit: 255
    t.string   "url",               limit: 255
    t.boolean  "sale_over",         limit: 1
    t.string   "place",             limit: 255
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

end
