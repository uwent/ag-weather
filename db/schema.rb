# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20201104180603) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "ar_internal_metadata", primary_key: "key", force: :cascade do |t|
    t.string   "value"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "data_imports", force: :cascade do |t|
    t.string   "type"
    t.date     "readings_on", null: false
    t.string   "status",      null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "evapotranspirations", id: :serial, force: :cascade do |t|
    t.decimal "potential_et"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.date "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "insolations", force: :cascade do |t|
    t.decimal  "recording"
    t.decimal  "latitude",   precision: 10, scale: 6
    t.decimal  "longitude",  precision: 10, scale: 6
    t.date     "date"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  create_table "pest_forecasts", id: :serial, force: :cascade do |t|
    t.date "date"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.integer "potato_blight_dsv", default: 0
    t.integer "carrot_foliar_dsv", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "alfalfa_weevil"
    t.float "asparagus_beetle"
    t.float "black_cutworm"
    t.float "brown_marmorated_stink_bug"
    t.float "cabbage_looper"
    t.float "cabbage_maggot"
    t.float "colorado_potato_beetle"
    t.float "corn_earworm"
    t.float "corn_rootworm"
    t.float "european_corn_borer"
    t.float "flea_beetle_mint"
    t.float "flea_beetle_crucifer"
    t.float "imported_cabbageworm"
    t.float "japanese_beetle"
    t.float "lygus_bug"
    t.float "mint_root_borer"
    t.float "onion_maggot"
    t.float "potato_psyllid"
    t.float "seedcorn_maggot"
    t.float "squash_vine_borer"
    t.float "stalk_borer"
    t.float "variegated_cutworm"
    t.float "western_bean_cutworm"
    t.float "western_flower_thrips"
  end

  create_table "station_hourly_observations", id: :serial, force: :cascade do |t|
    t.integer "station_id"
    t.date "reading_on"
    t.integer "hour"
    t.float "max_temperature"
    t.float "min_temperature"
    t.float "relative_humidity"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stations", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.float "latitude", null: false
    t.float "longitude", null: false
  end

  create_table "weather_data", force: :cascade do |t|
    t.decimal  "max_temperature"
    t.decimal  "min_temperature"
    t.decimal  "avg_temperature"
    t.decimal  "vapor_pressure"
    t.decimal  "latitude",            precision: 10, scale: 6
    t.decimal  "longitude",           precision: 10, scale: 6
    t.date     "date"
    t.datetime "created_at",                                               null: false
    t.datetime "updated_at",                                               null: false
    t.integer  "hours_rh_over_85",                             default: 0
    t.float    "avg_temp_rh_over_85"
    t.float    "avg_temp_rh_over_90"
    t.integer  "hours_rh_over_90"
  end

end
