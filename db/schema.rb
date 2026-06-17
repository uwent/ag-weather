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

ActiveRecord::Schema[8.1].define(version: 2026_04_07_212536) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", precision: nil, null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "data_imports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.string "message"
    t.string "status", null: false
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_data_imports_on_date"
    t.index ["status"], name: "index_data_imports_on_status"
  end

  create_table "degree_days", force: :cascade do |t|
    t.date "date", null: false
    t.float "dd_32"
    t.float "dd_38_75"
    t.float "dd_39p2_86"
    t.float "dd_41"
    t.float "dd_41_86"
    t.float "dd_42p8_86"
    t.float "dd_45"
    t.float "dd_45_80p1"
    t.float "dd_45_86"
    t.float "dd_48"
    t.float "dd_50"
    t.float "dd_50_86"
    t.float "dd_50_87p8"
    t.float "dd_50_90"
    t.float "dd_52"
    t.float "dd_52_86"
    t.float "dd_55_92"
    t.decimal "latitude", precision: 5, scale: 2, null: false
    t.decimal "longitude", precision: 5, scale: 2, null: false
    t.index ["date", "latitude", "longitude"], name: "index_degree_days_on_date_lat_long", unique: true
    t.index ["latitude", "longitude"], name: "index_degree_days_on_lat_long"
    t.index ["longitude"], name: "index_degree_days_on_longitude"
  end

  create_table "evapotranspirations", force: :cascade do |t|
    t.date "date", null: false
    t.decimal "latitude", precision: 5, scale: 2, null: false
    t.decimal "longitude", precision: 5, scale: 2, null: false
    t.float "potential_et"
    t.index ["date", "latitude", "longitude"], name: "index_evapotranspirations_on_date_lat_long", unique: true
    t.index ["latitude", "longitude"], name: "index_evapotranspirations_on_lat_long"
    t.index ["longitude"], name: "index_evapotranspirations_on_longitude"
  end

  create_table "insolations", force: :cascade do |t|
    t.date "date", null: false
    t.float "insolation"
    t.decimal "latitude", precision: 5, scale: 2, null: false
    t.decimal "longitude", precision: 5, scale: 2, null: false
    t.index ["date", "latitude", "longitude"], name: "index_insolations_on_date_lat_long", unique: true
    t.index ["latitude", "longitude"], name: "index_insolations_on_lat_long"
    t.index ["longitude"], name: "index_insolations_on_longitude"
  end

  create_table "pest_forecasts", force: :cascade do |t|
    t.integer "botcast_dsi", default: 0
    t.integer "carrot_foliar_dsv"
    t.integer "cercospora_div"
    t.date "date", null: false
    t.decimal "latitude", precision: 5, scale: 2, null: false
    t.decimal "longitude", precision: 5, scale: 2, null: false
    t.integer "potato_blight_dsv"
    t.float "potato_p_days"
    t.index ["date", "latitude", "longitude"], name: "index_pest_forecasts_on_date_lat_long", unique: true
    t.index ["latitude", "longitude"], name: "index_pest_forecasts_on_lat_long"
    t.index ["longitude"], name: "index_pest_forecasts_on_longitude"
  end

  create_table "precips", force: :cascade do |t|
    t.date "date", null: false
    t.decimal "latitude", precision: 5, scale: 2, null: false
    t.decimal "longitude", precision: 5, scale: 2, null: false
    t.float "precip"
    t.index ["date", "latitude", "longitude"], name: "index_precips_on_date_lat_long", unique: true
    t.index ["latitude", "longitude"], name: "index_precips_on_lat_long"
    t.index ["longitude"], name: "index_precips_on_longitude"
  end

  create_table "station_hourly_observations", force: :cascade do |t|
    t.integer "hour"
    t.float "max_temperature"
    t.float "min_temperature"
    t.date "reading_on"
    t.float "relative_humidity"
    t.integer "station_id"
  end

  create_table "stations", force: :cascade do |t|
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.decimal "latitude", precision: 5, scale: 2, null: false
    t.decimal "longitude", precision: 5, scale: 2, null: false
    t.string "name", null: false
    t.datetime "updated_at", default: -> { "now()" }, null: false
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "weather", force: :cascade do |t|
    t.float "avg_rh"
    t.float "avg_temp"
    t.float "avg_temp_rh_over_90"
    t.date "date", null: false
    t.float "dew_point"
    t.virtual "freezing", type: :integer, as: "((min_temp < ('-2'::integer)::double precision))::integer", stored: true
    t.virtual "frost", type: :integer, as: "((min_temp < (0)::double precision))::integer", stored: true
    t.integer "hours_rh_over_90"
    t.decimal "latitude", precision: 5, scale: 2, null: false
    t.decimal "longitude", precision: 5, scale: 2, null: false
    t.float "max_rh"
    t.float "max_temp"
    t.float "min_rh"
    t.float "min_temp"
    t.float "vapor_pressure"
    t.index ["date", "latitude", "longitude"], name: "index_weather_on_date_lat_long", unique: true
    t.index ["latitude", "longitude"], name: "index_weather_on_lat_long"
    t.index ["longitude"], name: "index_weather_on_longitude"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
