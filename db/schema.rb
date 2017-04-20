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

ActiveRecord::Schema.define(version: 20170413191300) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "data_imports", force: :cascade do |t|
    t.string   "type"
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

  create_table "pest_forecasts", force: :cascade do |t|
    t.date     "date"
    t.decimal  "latitude",                   precision: 10, scale: 6
    t.decimal  "longitude",                  precision: 10, scale: 6
    t.integer  "potato_blight_dsv",                                   default: 0
    t.integer  "carrot_foliar_dsv",                                   default: 0
    t.datetime "created_at",                                                        null: false
    t.datetime "updated_at",                                                        null: false
    t.float    "alfalfa_weevil",                                      default: 0.0
    t.float    "asparagus_beetle",                                    default: 0.0
    t.float    "black_cutworm",                                       default: 0.0
    t.float    "brown_marmorated_stink_bug",                          default: 0.0
    t.float    "cabbage_looper",                                      default: 0.0
    t.float    "cabbage_maggot",                                      default: 0.0
    t.float    "colorado_potato_beetle",                              default: 0.0
    t.float    "corn_earworm",                                        default: 0.0
    t.float    "corn_rootworm",                                       default: 0.0
    t.float    "european_corn_borer",                                 default: 0.0
    t.float    "flea_beetle_mint",                                    default: 0.0
    t.float    "flea_beetle_crucifer",                                default: 0.0
    t.float    "imported_cabbageworm",                                default: 0.0
    t.float    "japanese_beetle",                                     default: 0.0
    t.float    "lygus_bug",                                           default: 0.0
    t.float    "mint_root_borer",                                     default: 0.0
    t.float    "onion_maggot",                                        default: 0.0
    t.float    "potato_psyllid",                                      default: 0.0
    t.float    "seedcorn_maggot",                                     default: 0.0
    t.float    "squash_vine_borer",                                   default: 0.0
    t.float    "stalk_borer",                                         default: 0.0
    t.float    "variegated_cutworm",                                  default: 0.0
    t.float    "western_bean_cutworm",                                default: 0.0
    t.float    "western_flower_thrips",                               default: 0.0
  end

  add_index "pest_forecasts", ["date", "longitude", "latitude"], name: "index_pest_forecasts_on_date_and_longitude_and_latitude", using: :btree
  add_index "pest_forecasts", ["date"], name: "index_pest_forecasts_on_date", using: :btree

  create_table "weather_data", force: :cascade do |t|
    t.decimal  "max_temperature"
    t.decimal  "min_temperature"
    t.decimal  "avg_temperature"
    t.decimal  "vapor_pressure"
    t.decimal  "latitude",         precision: 10, scale: 6
    t.decimal  "longitude",        precision: 10, scale: 6
    t.date     "date"
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
    t.integer  "hours_rh_over_85",                          default: 0
  end

  add_index "weather_data", ["date"], name: "weather_data_date", using: :btree
  add_index "weather_data", ["latitude", "longitude", "date"], name: "weather_data_lat_long_date", using: :btree
  add_index "weather_data", ["latitude", "longitude"], name: "weather_data_lat_long", using: :btree

end
