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

ActiveRecord::Schema.define(version: 20160201021837) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "data_imports", force: :cascade do |t|
    t.string   "type",        null: false
    t.date     "readings_on", null: false
    t.string   "status",      null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "evapotranspirations", force: :cascade do |t|
    t.decimal  "potential_et"
    t.decimal  "latitude",     precision: 10, scale: 6
    t.decimal  "longitude",    precision: 10, scale: 6
    t.date     "date"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
  end

  create_table "insolations", force: :cascade do |t|
    t.decimal  "recording"
    t.decimal  "latitude",   precision: 10, scale: 6
    t.decimal  "longitude",  precision: 10, scale: 6
    t.date     "date"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  create_table "weather_data", force: :cascade do |t|
    t.decimal  "max_temperature"
    t.decimal  "min_temperature"
    t.decimal  "avg_temperature"
    t.decimal  "vapor_pressure"
    t.decimal  "latitude",        precision: 10, scale: 6
    t.decimal  "longitude",       precision: 10, scale: 6
    t.date     "date"
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
  end

end
