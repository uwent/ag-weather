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

ActiveRecord::Schema.define(version: 2021_07_30_233300) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "data_imports", force: :cascade do |t|
    t.string "type"
    t.date "readings_on", null: false
    t.string "status", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "message"
  end

  create_table "evapotranspirations", force: :cascade do |t|
    t.decimal "potential_et", precision: 10, scale: 6
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.date "date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["date"], name: "index_evapotranspirations_on_date"
    t.index ["latitude", "longitude", "date"], name: "index_evapotranspirations_on_latitude_and_longitude_and_date", unique: true
    t.index ["latitude", "longitude"], name: "index_evapotranspirations_on_latitude_and_longitude"
  end

  create_table "insolations", force: :cascade do |t|
    t.decimal "insolation", precision: 10, scale: 6
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.date "date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["date"], name: "index_insolations_on_date"
    t.index ["latitude", "longitude", "date"], name: "index_insolations_on_latitude_and_longitude_and_date", unique: true
    t.index ["latitude", "longitude"], name: "index_insolations_on_latitude_and_longitude"
  end

  create_table "pest_forecasts", force: :cascade do |t|
    t.date "date"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.integer "potato_blight_dsv", default: 0
    t.integer "carrot_foliar_dsv", default: 0
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.decimal "dd_48_none", precision: 10, scale: 6
    t.decimal "dd_50_86", precision: 10, scale: 6
    t.decimal "dd_54_92", precision: 10, scale: 6
    t.decimal "dd_50_90", precision: 10, scale: 6
    t.decimal "dd_42p8_86", precision: 10, scale: 6
    t.decimal "dd_52_none", precision: 10, scale: 6
    t.decimal "dd_55_92", precision: 10, scale: 6
    t.decimal "dd_41_none", precision: 10, scale: 6
    t.decimal "dd_39p2_86", precision: 10, scale: 6
    t.decimal "dd_41_86", precision: 10, scale: 6
    t.decimal "dd_41_88", precision: 10, scale: 6
    t.decimal "dd_45_none", precision: 10, scale: 6
    t.decimal "potato_p_days", precision: 10, scale: 6
    t.integer "cercospora_div", default: 0
    t.decimal "dd_50_none", precision: 10, scale: 6
    t.decimal "dd_50_88", precision: 10, scale: 6
    t.decimal "dd_45_86", precision: 10, scale: 6
    t.index ["date"], name: "index_pest_forecasts_on_date"
    t.index ["latitude", "longitude", "date"], name: "index_pest_forecasts_on_latitude_and_longitude_and_date", unique: true
    t.index ["latitude", "longitude"], name: "index_pest_forecasts_on_latitude_and_longitude"
  end

  create_table "station_hourly_observations", force: :cascade do |t|
    t.integer "station_id"
    t.date "reading_on"
    t.integer "hour"
    t.float "max_temperature"
    t.float "min_temperature"
    t.float "relative_humidity"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stations", force: :cascade do |t|
    t.string "name", null: false
    t.float "latitude", null: false
    t.float "longitude", null: false
  end

  create_table "weather_data", force: :cascade do |t|
    t.decimal "max_temperature", precision: 10, scale: 6
    t.decimal "min_temperature", precision: 10, scale: 6
    t.decimal "avg_temperature", precision: 10, scale: 6
    t.decimal "vapor_pressure", precision: 10, scale: 6
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.date "date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "hours_rh_over_85", default: 0
    t.decimal "avg_temp_rh_over_85", precision: 10, scale: 6
    t.decimal "avg_temp_rh_over_90", precision: 10, scale: 6
    t.integer "hours_rh_over_90"
    t.index ["date"], name: "index_weather_data_on_date"
    t.index ["latitude", "longitude", "date"], name: "index_weather_data_on_latitude_and_longitude_and_date", unique: true
    t.index ["latitude", "longitude"], name: "index_weather_data_on_latitude_and_longitude"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
