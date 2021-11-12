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

ActiveRecord::Schema.define(version: 2021_11_11_235150) do

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
    t.float "potential_et"
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
    t.float "insolation"
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
    t.integer "potato_blight_dsv"
    t.integer "carrot_foliar_dsv"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.float "dd_48_none"
    t.float "dd_50_86"
    t.float "dd_54_92"
    t.float "dd_50_90"
    t.float "dd_42p8_86"
    t.float "dd_52_none"
    t.float "dd_55_92"
    t.float "dd_41_none"
    t.float "dd_39p2_86"
    t.float "dd_41_86"
    t.float "dd_41_88"
    t.float "dd_45_none"
    t.float "potato_p_days"
    t.integer "cercospora_div"
    t.float "dd_50_none"
    t.float "dd_50_88"
    t.float "dd_45_86"
    t.index ["date"], name: "index_pest_forecasts_on_date"
    t.index ["latitude", "longitude", "date"], name: "index_pest_forecasts_on_latitude_and_longitude_and_date", unique: true
    t.index ["latitude", "longitude"], name: "index_pest_forecasts_on_latitude_and_longitude"
  end

  create_table "precips", force: :cascade do |t|
    t.date "date"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.float "precip"
    t.index ["date", "latitude", "longitude"], name: "index_precips_on_date_and_latitude_and_longitude", unique: true
    t.index ["date"], name: "index_precips_on_date"
    t.index ["latitude", "longitude"], name: "index_precips_on_latitude_and_longitude"
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
    t.decimal "latitude", precision: 10, scale: 6, null: false
    t.decimal "longitude", precision: 10, scale: 6, null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.boolean "admin"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "weather_data", force: :cascade do |t|
    t.float "max_temperature"
    t.float "min_temperature"
    t.float "avg_temperature"
    t.float "vapor_pressure"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.date "date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "hours_rh_over_85"
    t.float "avg_temp_rh_over_85"
    t.float "avg_temp_rh_over_90"
    t.integer "hours_rh_over_90"
    t.float "dew_point"
    t.index ["date"], name: "index_weather_data_on_date"
    t.index ["latitude", "longitude", "date"], name: "index_weather_data_on_latitude_and_longitude_and_date", unique: true
    t.index ["latitude", "longitude"], name: "index_weather_data_on_latitude_and_longitude"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
