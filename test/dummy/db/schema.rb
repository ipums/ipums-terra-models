# Copyright (c) 2012-2017 Regents of the University of Minnesota
#
# This file is part of the Minnesota Population Center's IPUMS Terra Project.
# For copyright and licensing information, see the NOTICE and LICENSE files
# in this project's top-level directory, and also on-line at:
#   https://github.com/mnpopcenter/ipums-terra-models

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

ActiveRecord::Schema.define(version: 20151216203903) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"
  enable_extension "hstore"

  create_table "api_logs", force: true do |t|
    t.text     "api_key"
    t.text     "action"
    t.text     "extra"
    t.datetime "created_at", default: "now()"
    t.datetime "updated_at", default: "now()"
  end

  add_index "api_logs", ["api_key"], name: "index_api_logs_on_api_key", using: :btree

  create_table "area_data_raster_variable_mnemonic_lookups", force: true do |t|
    t.string   "composite_mnemonic",      default: "not null"
    t.string   "mnemonic",                default: "not null"
    t.string   "raster_operation_opcode"
    t.string   "geog_level",              default: "not null"
    t.string   "dataset_label",           default: "not null"
    t.text     "description"
    t.datetime "created_at",              default: "now()"
    t.datetime "updated_at",              default: "now()"
  end

  add_index "area_data_raster_variable_mnemonic_lookups", ["composite_mnemonic"], name: "index_area_data_raster_variable_composite_mnemonic", using: :btree
  add_index "area_data_raster_variable_mnemonic_lookups", ["mnemonic"], name: "area_data_raster_variable_lookups_mnemonic", using: :btree

# Could not dump table "area_data_rasters" because of following StandardError
#   Unknown type 'raster' for column 'rast'

  create_table "area_data_statistics", force: true do |t|
    t.integer  "geog_instance_id",      limit: 8
    t.integer  "area_data_variable_id", limit: 8
    t.decimal  "mean",                            precision: 64, scale: 10
    t.decimal  "stddev",                          precision: 64, scale: 10
    t.datetime "created_at",                                                default: "now()"
    t.datetime "updated_at",                                                default: "now()"
  end

  create_table "area_data_table_group_memberships", id: false, force: true do |t|
    t.integer "area_data_table_id",       limit: 8
    t.integer "area_data_table_group_id", limit: 8
  end

  create_table "area_data_table_groups", force: true do |t|
    t.string   "name"
    t.integer  "display_order"
    t.boolean  "hidden"
    t.datetime "created_at",    default: "now()"
    t.datetime "updated_at",    default: "now()"
  end

  add_index "area_data_table_groups", ["name"], name: "index_area_data_table_groups_on_name", using: :btree

  create_table "area_data_tables", force: true do |t|
    t.string   "label"
    t.string   "code",               limit: 10
    t.text     "documentation"
    t.text     "universe"
    t.string   "aggregation_method"
    t.string   "additivity"
    t.boolean  "hidden"
    t.datetime "created_at",                    default: "now()"
    t.datetime "updated_at",                    default: "now()"
  end

  create_table "area_data_values", force: true do |t|
    t.integer  "sample_level_area_data_variable_id", limit: 8
    t.integer  "area_data_variable_id",              limit: 8
    t.integer  "geog_instance_id",                   limit: 8
    t.decimal  "value",                                         precision: 64, scale: 10
    t.decimal  "error",                                         precision: 64, scale: 10
    t.integer  "precision"
    t.datetime "created_at",                                                              default: "now()"
    t.datetime "updated_at",                                                              default: "now()"
    t.text     "mnemonic_long"
    t.text     "codebook_description"
    t.string   "synthetic_mnemonic",                 limit: 32
    t.decimal  "margin_value",                                  precision: 64, scale: 10
    t.decimal  "special_value",                                 precision: 64, scale: 10
  end

  add_index "area_data_values", ["area_data_variable_id"], name: "index_area_data_values_on_area_data_variable_id", using: :btree
  add_index "area_data_values", ["geog_instance_id"], name: "index_area_data_values_on_geog_instance_id", using: :btree
  add_index "area_data_values", ["sample_level_area_data_variable_id"], name: "index_area_data_values_on_sample_level_area_data_variable_id", using: :btree
  add_index "area_data_values", ["synthetic_mnemonic"], name: "index_area_data_values_on_synthetic_mnemonic", using: :btree

  create_table "area_data_variable_constructions", force: true do |t|
    t.integer  "variable_id",           limit: 8,                   null: false
    t.integer  "area_data_variable_id", limit: 8,                   null: false
    t.datetime "created_at",                      default: "now()"
    t.datetime "updated_at",                      default: "now()"
  end

  add_index "area_data_variable_constructions", ["area_data_variable_id"], name: "index_area_data_variable_constructions_on_area_data_variable_id", using: :btree
  add_index "area_data_variable_constructions", ["variable_id"], name: "index_area_data_variable_constructions_on_variable_id", using: :btree

  create_table "area_data_variables", force: true do |t|
    t.integer  "area_data_table_id",  limit: 8
    t.integer  "measurement_type_id", limit: 8
    t.string   "mnemonic",            limit: 32
    t.string   "long_mnemonic",       limit: 64
    t.string   "label"
    t.text     "description"
    t.boolean  "hidden"
    t.datetime "created_at",                     default: "now()"
    t.datetime "updated_at",                     default: "now()"
  end

  add_index "area_data_variables", ["area_data_table_id"], name: "index_area_data_variables_on_area_data_table_id", using: :btree
  add_index "area_data_variables", ["hidden"], name: "index_area_data_variables_on_hidden", using: :btree
  add_index "area_data_variables", ["measurement_type_id"], name: "index_area_data_variables_on_measurement_type_id", using: :btree
  add_index "area_data_variables", ["mnemonic"], name: "index_area_data_variables_on_mnemonic", using: :btree

  create_table "area_data_variables_topics", id: false, force: true do |t|
    t.integer "area_data_variable_id", limit: 8, null: false
    t.integer "topic_id",              limit: 8, null: false
  end

  add_index "area_data_variables_topics", ["area_data_variable_id"], name: "index_area_data_variables_topics_on_area_data_variable_id", using: :btree
  add_index "area_data_variables_topics", ["topic_id"], name: "index_area_data_variables_topics_on_topic_id", using: :btree

  create_table "attached_variable_pointers", force: true do |t|
    t.string   "mnemonic"
    t.string   "suffix"
    t.string   "label"
    t.datetime "created_at", default: "now()"
    t.datetime "updated_at", default: "now()"
  end

  create_table "bad_advs", id: false, force: true do |t|
    t.integer "advar_id", limit: 8
    t.integer "ts_id",    limit: 8
    t.integer "sladv_id", limit: 8
    t.string  "mnemonic", limit: 32
    t.string  "label"
    t.integer "count",    limit: 8
  end

# Could not dump table "boundaries" because of following StandardError
#   Unknown type 'geography(MultiPolygon,4326)' for column 'geog'

  create_table "build_statuses", force: true do |t|
    t.integer  "val"
    t.string   "label",       limit: 32
    t.string   "description", limit: 128
    t.datetime "created_at",              default: "now()"
    t.datetime "updated_at",              default: "now()"
  end

  create_table "cache_items", force: true do |t|
    t.string   "key"
    t.text     "value"
    t.text     "meta_info"
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cache_items", ["expires_at"], name: "index_cache_items_on_expires_at", using: :btree
  add_index "cache_items", ["key"], name: "index_cache_items_on_key", unique: true, using: :btree
  add_index "cache_items", ["updated_at"], name: "index_cache_items_on_updated_at", using: :btree

  create_table "categories", force: true do |t|
    t.integer  "variable_id",    limit: 8
    t.integer  "metadata_id"
    t.string   "code"
    t.string   "label",          limit: 1024
    t.string   "general_label"
    t.string   "syntax_label"
    t.integer  "indent"
    t.integer  "general_indent"
    t.boolean  "informational"
    t.datetime "created_at",                  default: "now()"
    t.datetime "updated_at",                  default: "now()"
  end

  add_index "categories", ["variable_id"], name: "index_categories_on_variable_id", using: :btree

  create_table "common_variables", force: true do |t|
    t.string   "variable_name", limit: 25
    t.string   "record_type",   limit: 10
    t.datetime "created_at",               default: "now()"
    t.datetime "updated_at",               default: "now()"
  end

  add_index "common_variables", ["variable_name"], name: "index_common_variables_on_variable_name", using: :btree

  create_table "countries", force: true do |t|
    t.string   "short_name"
    t.string   "full_name"
    t.string   "continent"
    t.boolean  "is_old"
    t.text     "abbrev_long"
    t.boolean  "hide_status"
    t.string   "stats_office"
    t.datetime "created_at",                 default: "now()"
    t.datetime "updated_at",                 default: "now()"
    t.integer  "global_region_id", limit: 8
    t.boolean  "is_erf"
  end

  add_index "countries", ["abbrev_long"], name: "index_countries_on_abbrev_long", using: :btree
  add_index "countries", ["continent"], name: "index_countries_on_continent", using: :btree
  add_index "countries", ["full_name"], name: "index_countries_on_full_name", using: :btree
  add_index "countries", ["global_region_id"], name: "index_countries_on_global_region_id", using: :btree
  add_index "countries", ["is_erf"], name: "index_countries_on_is_erf", using: :btree
  add_index "countries", ["short_name"], name: "index_countries_on_short_name", using: :btree

  create_table "country_comparabilities", force: true do |t|
    t.integer  "variable_id",   limit: 8
    t.integer  "country_id",    limit: 8
    t.text     "comparability"
    t.datetime "created_at",              default: "now()"
    t.datetime "updated_at",              default: "now()"
  end

  create_table "country_levels", force: true do |t|
    t.integer  "geog_unit_id",    limit: 8
    t.integer  "country_id",      limit: 8
    t.string   "label"
    t.string   "code"
    t.string   "level_order"
    t.datetime "created_at",                  default: "now()"
    t.datetime "updated_at",                  default: "now()"
    t.string   "localized_label", limit: 128
  end

  add_index "country_levels", ["code"], name: "index_country_levels_on_code", unique: true, using: :btree

  create_table "empty_sladvs", id: false, force: true do |t|
    t.integer "sladv_id",  limit: 8
    t.string  "adv_label"
    t.string  "sgl_label"
    t.integer "count",     limit: 8
  end

  create_table "error_events", force: true do |t|
    t.integer  "user_id",       limit: 8
    t.text     "message",                                   null: false
    t.text     "supplementary"
    t.datetime "created_at",              default: "now()"
    t.datetime "updated_at",              default: "now()"
  end

  create_table "extract_data_artifacts", force: true do |t|
    t.integer  "extract_request_id",    limit: 8
    t.text     "data_filename"
    t.text     "boundary_filename"
    t.text     "data_year"
    t.text     "geographic_level"
    t.datetime "created_at",                      default: "now()"
    t.datetime "updated_at",                      default: "now()"
    t.hstore   "variables_description"
  end

  add_index "extract_data_artifacts", ["extract_request_id"], name: "index_extract_data_artifacts_on_extract_request_id", using: :btree
  add_index "extract_data_artifacts", ["variables_description"], name: "extract_data_artifacts_variables_description", using: :gin

  create_table "extract_request_area_data_raster_variable_mnemonic_lookups", force: true do |t|
    t.integer  "area_data_raster_variable_mnemonic_lookup_id", limit: 8
    t.integer  "extract_request_id",                           limit: 8
    t.datetime "created_at",                                             default: "now()"
    t.datetime "updated_at",                                             default: "now()"
  end

  add_index "extract_request_area_data_raster_variable_mnemonic_lookups", ["area_data_raster_variable_mnemonic_lookup_id"], name: "er_adrv_mnemonic_lookup_index", using: :btree
  add_index "extract_request_area_data_raster_variable_mnemonic_lookups", ["extract_request_id"], name: "er_adrv", using: :btree

  create_table "extract_request_error_events", force: true do |t|
    t.integer  "extract_request_id", limit: 8
    t.integer  "error_event_id",     limit: 8
    t.datetime "created_at",                   default: "now()"
    t.datetime "updated_at",                   default: "now()"
  end

  create_table "extract_request_submissions", force: true do |t|
    t.integer  "extract_request_id", limit: 8
    t.datetime "submitted_at"
    t.datetime "created_at",                   default: "now()"
    t.datetime "updated_at",                   default: "now()"
  end

  create_table "extract_requests", force: true do |t|
    t.boolean  "boundary_files",                  default: false
    t.text     "notes"
    t.integer  "user_id",             limit: 8
    t.boolean  "submitted",                       default: false
    t.datetime "created_at",                      default: "now()"
    t.datetime "updated_at",                      default: "now()"
    t.integer  "revision_of_id",      limit: 8
    t.string   "file_type",           limit: 64
    t.string   "uuid",                limit: 36
    t.boolean  "raster_only",                     default: false
    t.boolean  "send_to_irods",                   default: false
    t.text     "extract_url"
    t.string   "request_url",         limit: 256
    t.integer  "begin_extract_time",  limit: 8
    t.integer  "finish_extract_time", limit: 8
    t.integer  "total_time",          limit: 8
    t.integer  "revision_of",         limit: 8
    t.string   "commit",              limit: 64
    t.string   "origin"
    t.boolean  "processing",                      default: false
    t.text     "extract_grouping"
    t.hstore   "data"
    t.string   "title"
    t.text     "extract_filename"
    t.datetime "submitted_at"
    t.integer  "tp_web_build_number", limit: 8
    t.integer  "tp_xtr_build_number", limit: 8
  end

  add_index "extract_requests", ["data"], name: "extract_requests_gin_data", using: :gin
  add_index "extract_requests", ["send_to_irods"], name: "index_extract_requests_on_send_to_irods", using: :btree
  add_index "extract_requests", ["tp_web_build_number"], name: "index_extract_requests_on_tp_web_build_number", using: :btree
  add_index "extract_requests", ["tp_xtr_build_number"], name: "index_extract_requests_on_tp_xtr_build_number", using: :btree
  add_index "extract_requests", ["uuid"], name: "index_extract_requests_on_uuid", unique: true, using: :btree

  create_table "extract_requests_labels", id: false, force: true do |t|
    t.integer "extract_request_id", limit: 8
    t.integer "label_id",           limit: 8
    t.integer "user_id",            limit: 8
    t.boolean "visible",                      default: true, null: false
  end

  create_table "extract_statuses", force: true do |t|
    t.integer  "extract_request_id",   limit: 8
    t.string   "status",               limit: 128, default: "building request"
    t.integer  "status_definition_id", limit: 8
    t.datetime "created_at",                       default: "now()"
    t.datetime "updated_at",                       default: "now()"
  end

  create_table "extract_types", force: true do |t|
    t.string   "label",      limit: 64
    t.datetime "created_at",            default: "now()"
    t.datetime "updated_at",            default: "now()"
  end

  create_table "frequencies", force: true do |t|
    t.integer  "category_id",       limit: 8
    t.integer  "sample_id",         limit: 8
    t.integer  "frequency"
    t.integer  "variable_id",       limit: 8
    t.string   "code",              limit: 50
    t.datetime "created_at",                   default: "now()"
    t.datetime "updated_at",                   default: "now()"
    t.integer  "frequency_type_id", limit: 8
  end

  add_index "frequencies", ["category_id"], name: "index_frequencies_on_category_id", using: :btree
  add_index "frequencies", ["sample_id"], name: "index_frequencies_on_sample_id", using: :btree
  add_index "frequencies", ["variable_id"], name: "index_frequencies_on_variable_id", using: :btree

  create_table "geog_instances", force: true do |t|
    t.integer  "sample_geog_level_id", limit: 8
    t.integer  "parent_id",            limit: 8
    t.string   "label"
    t.decimal  "code",                            precision: 20, scale: 0
    t.decimal  "shape_area"
    t.text     "notes"
    t.datetime "created_at",                                               default: "now()"
    t.datetime "updated_at",                                               default: "now()"
    t.string   "geog_code",            limit: 64
    t.string   "str_code",             limit: 64
    t.integer  "terrapop_sample_id",   limit: 8
  end

  add_index "geog_instances", ["code"], name: "index_geog_instances_on_code", using: :btree
  add_index "geog_instances", ["geog_code"], name: "index_geog_instances_on_geog_code", using: :btree
  add_index "geog_instances", ["parent_id"], name: "index_geog_instances_on_parent_id", using: :btree
  add_index "geog_instances", ["sample_geog_level_id"], name: "index_geog_instances_on_sample_geog_level_id", using: :btree
  add_index "geog_instances", ["str_code"], name: "index_geog_instances_on_str_code", using: :btree
  add_index "geog_instances", ["terrapop_sample_id"], name: "index_geog_instances_on_terrapop_sample_id", using: :btree

  create_table "geog_units", force: true do |t|
    t.string   "label"
    t.string   "code",       limit: 8
    t.datetime "created_at",           default: "now()"
    t.datetime "updated_at",           default: "now()"
  end

  create_table "global_region_types", force: true do |t|
    t.string   "name",       limit: 128,                   null: false
    t.datetime "created_at",             default: "now()"
    t.datetime "updated_at",             default: "now()"
  end

  create_table "global_regions", force: true do |t|
    t.string   "name",                  limit: 128,                   null: false
    t.datetime "created_at",                        default: "now()"
    t.datetime "updated_at",                        default: "now()"
    t.integer  "global_region_type_id", limit: 8
    t.integer  "sort_order",                        default: 0
    t.string   "short_code",            limit: 3
  end

  add_index "global_regions", ["name"], name: "index_global_regions_on_name", using: :btree
  add_index "global_regions", ["short_code"], name: "index_global_regions_on_short_code", using: :btree

  create_table "heartbeat_pulses", force: true do |t|
    t.integer  "heartbeat_id", limit: 8
    t.datetime "created_at",             default: "now()"
    t.datetime "updated_at",             default: "now()"
  end

  add_index "heartbeat_pulses", ["heartbeat_id"], name: "index_heartbeat_pulses_on_heartbeat_id", using: :btree

  create_table "heartbeats", force: true do |t|
    t.string   "uuid",       limit: 36,                   null: false
    t.datetime "created_at",            default: "now()"
    t.datetime "updated_at",            default: "now()"
  end

  add_index "heartbeats", ["uuid"], name: "index_heartbeats_on_uuid", using: :btree

  create_table "insert_html_fragments", force: true do |t|
    t.string   "name"
    t.text     "content"
    t.datetime "created_at", default: "now()"
    t.datetime "updated_at", default: "now()"
  end

  add_index "insert_html_fragments", ["name"], name: "index_insert_html_fragments_on_name", using: :btree

  create_table "links", force: true do |t|
    t.string   "name"
    t.string   "location"
    t.datetime "created_at", default: "now()"
    t.datetime "updated_at", default: "now()"
  end

  create_table "map_unit_raster_datasets", force: true do |t|
    t.integer  "map_unit_id",       limit: 8,                   null: false
    t.integer  "raster_dataset_id", limit: 8,                   null: false
    t.datetime "created_at",                  default: "now()"
    t.datetime "updated_at",                  default: "now()"
  end

  add_index "map_unit_raster_datasets", ["map_unit_id"], name: "index_map_unit_raster_datasets_on_map_unit_id", using: :btree
  add_index "map_unit_raster_datasets", ["raster_dataset_id"], name: "index_map_unit_raster_datasets_on_raster_dataset_id", using: :btree

  create_table "map_units", force: true do |t|
    t.string   "unit_long",  limit: 48,                   null: false
    t.string   "unit_short", limit: 8,                    null: false
    t.datetime "created_at",            default: "now()"
    t.datetime "updated_at",            default: "now()"
  end

  create_table "maps", force: true do |t|
    t.integer  "source_id",              limit: 8
    t.integer  "country_id",             limit: 8
    t.integer  "country_level_id",       limit: 8
    t.date     "year_represented"
    t.integer  "id_code_digits",         limit: 8
    t.boolean  "labeled"
    t.string   "name",                   limit: 128
    t.string   "source_file"
    t.integer  "num_units",              limit: 8
    t.text     "description"
    t.datetime "created_at",                         default: "now()"
    t.datetime "updated_at",                         default: "now()"
    t.date     "represented_year_start"
    t.date     "represented_year_end"
    t.integer  "terrapop_sample_id",     limit: 8
    t.text     "iso19115_xml"
  end

  add_index "maps", ["represented_year_end"], name: "index_maps_on_represented_year_end", using: :btree
  add_index "maps", ["represented_year_start"], name: "index_maps_on_represented_year_start", using: :btree

  create_table "measurement_types", force: true do |t|
    t.string   "label",      limit: 128
    t.text     "notes"
    t.datetime "created_at",             default: "now()"
    t.datetime "updated_at",             default: "now()"
  end

  create_table "new_rasters", force: true do |t|
    t.integer  "raster_variable_id",       limit: 8
    t.text     "table_name"
    t.integer  "area_reference_id",        limit: 8
    t.integer  "second_area_reference_id", limit: 8
    t.text     "r_table_schema"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "new_rasters", ["area_reference_id"], name: "index_new_rasters_on_area_reference_id", using: :btree
  add_index "new_rasters", ["raster_variable_id"], name: "index_new_rasters_on_raster_variable_id", using: :btree
  add_index "new_rasters", ["second_area_reference_id"], name: "index_new_rasters_on_second_area_reference_id", using: :btree

  create_table "nhgis_metadata_stores", force: true do |t|
    t.string   "ds_code",              limit: 128
    t.string   "dt_label",             limit: 256
    t.string   "adv_label",            limit: 64
    t.integer  "adv_id",               limit: 8
    t.integer  "ts_id",                limit: 8
    t.string   "ts_label",             limit: 128
    t.integer  "tst_id",               limit: 8
    t.string   "tst_label",            limit: 128
    t.integer  "gl_id",                limit: 8
    t.string   "gl_istads_id",         limit: 128
    t.integer  "dg_id",                limit: 8
    t.text     "dg_relative_pathname"
    t.integer  "df_id",                limit: 8
    t.string   "df_filename",          limit: 64
    t.datetime "created_at",                       default: "now()"
    t.datetime "updated_at",                       default: "now()"
    t.integer  "ds_id",                limit: 8
  end

  add_index "nhgis_metadata_stores", ["adv_id"], name: "index_nhgis_metadata_stores_on_adv_id", using: :btree
  add_index "nhgis_metadata_stores", ["df_id"], name: "index_nhgis_metadata_stores_on_df_id", using: :btree
  add_index "nhgis_metadata_stores", ["dg_id"], name: "index_nhgis_metadata_stores_on_dg_id", using: :btree
  add_index "nhgis_metadata_stores", ["gl_id"], name: "index_nhgis_metadata_stores_on_gl_id", using: :btree
  add_index "nhgis_metadata_stores", ["gl_istads_id"], name: "index_nhgis_metadata_stores_on_gl_istads_id", using: :btree
  add_index "nhgis_metadata_stores", ["ts_id"], name: "index_nhgis_metadata_stores_on_ts_id", using: :btree
  add_index "nhgis_metadata_stores", ["tst_id"], name: "index_nhgis_metadata_stores_on_tst_id", using: :btree

  create_table "raster_categories", force: true do |t|
    t.integer  "raster_variable_id", limit: 8
    t.integer  "code",               limit: 8,                   null: false
    t.text     "label"
    t.datetime "created_at",                   default: "now()"
    t.datetime "updated_at",                   default: "now()"
  end

  create_table "raster_category_statistics", force: true do |t|
    t.integer  "geog_instance_id",   limit: 8
    t.integer  "raster_variable_id", limit: 8
    t.integer  "raster_category_id", limit: 8
    t.integer  "code",               limit: 8
    t.integer  "total_count",        limit: 8
    t.datetime "created_at",                   default: "now()"
    t.datetime "updated_at",                   default: "now()"
  end

  add_index "raster_category_statistics", ["geog_instance_id"], name: "index_raster_category_statistics_on_geog_instance_id", using: :btree
  add_index "raster_category_statistics", ["raster_category_id"], name: "index_raster_category_statistics_on_raster_category_id", using: :btree
  add_index "raster_category_statistics", ["raster_variable_id"], name: "index_raster_category_statistics_on_raster_variable_id", using: :btree

  create_table "raster_data_types", force: true do |t|
    t.string   "code",       limit: 32,                   null: false
    t.string   "label",      limit: 64,                   null: false
    t.datetime "created_at",            default: "now()"
    t.datetime "updated_at",            default: "now()"
  end

  create_table "raster_dataset_groups", force: true do |t|
    t.string   "label"
    t.text     "description"
    t.datetime "created_at",  default: "now()"
    t.datetime "updated_at",  default: "now()"
    t.string   "mnemonic"
  end

  create_table "raster_dataset_raster_data_types", force: true do |t|
    t.integer  "raster_dataset_id",   limit: 8
    t.integer  "raster_data_type_id", limit: 8
    t.datetime "created_at",                    default: "now()"
    t.datetime "updated_at",                    default: "now()"
  end

  add_index "raster_dataset_raster_data_types", ["raster_data_type_id"], name: "index_raster_dataset_raster_data_types_on_raster_data_type_id", using: :btree
  add_index "raster_dataset_raster_data_types", ["raster_dataset_id"], name: "index_raster_dataset_raster_data_types_on_raster_dataset_id", using: :btree

  create_table "raster_dataset_raster_dataset_units", force: true do |t|
    t.integer  "raster_dataset_id",      limit: 8
    t.integer  "raster_dataset_unit_id", limit: 8
    t.datetime "created_at",                       default: "now()"
    t.datetime "updated_at",                       default: "now()"
  end

  add_index "raster_dataset_raster_dataset_units", ["raster_dataset_id"], name: "index_rdrdu_raster_dataset_id", using: :btree
  add_index "raster_dataset_raster_dataset_units", ["raster_dataset_unit_id"], name: "index_rdrdu_raster_dataset_unit_id", using: :btree

  create_table "raster_dataset_raster_variables", force: true do |t|
    t.integer  "raster_variable_id", limit: 8,                   null: false
    t.integer  "raster_dataset_id",  limit: 8,                   null: false
    t.datetime "created_at",                   default: "now()"
    t.datetime "updated_at",                   default: "now()"
  end

  add_index "raster_dataset_raster_variables", ["raster_dataset_id"], name: "index_raster_dataset_raster_variables_on_raster_dataset_id", using: :btree
  add_index "raster_dataset_raster_variables", ["raster_variable_id"], name: "index_raster_dataset_raster_variables_on_raster_variable_id", using: :btree

  create_table "raster_dataset_units", force: true do |t|
    t.string   "label",      limit: 128
    t.string   "mnemonic",   limit: 32
    t.datetime "created_at",             default: "now()"
    t.datetime "updated_at",             default: "now()"
  end

  create_table "raster_datasets", force: true do |t|
    t.string   "mnemonic",                                                                                    null: false
    t.string   "label"
    t.integer  "resolution_id",               limit: 8
    t.string   "source"
    t.string   "coord_sys",                                                        default: "lat/long WGS84"
    t.integer  "begin_year"
    t.integer  "end_year"
    t.text     "usage_rights"
    t.text     "description"
    t.text     "citation"
    t.datetime "created_at",                                                       default: "now()"
    t.datetime "updated_at",                                                       default: "now()"
    t.text     "long_extent"
    t.string   "short_extent",                limit: 64
    t.string   "period"
    t.boolean  "has_circa",                                                        default: false
    t.text     "process_summary"
    t.text     "source_data"
    t.text     "temporal_extent_description"
    t.text     "provider"
    t.decimal  "north_extent",                           precision: 64, scale: 10
    t.decimal  "south_extent",                           precision: 64, scale: 10
    t.decimal  "east_extent",                            precision: 64, scale: 10
    t.decimal  "west_extent",                            precision: 64, scale: 10
    t.integer  "raster_band_index",           limit: 8,                            default: -1,               null: false
    t.integer  "raster_dataset_group_id",     limit: 8
  end

  add_index "raster_datasets", ["raster_band_index"], name: "index_raster_datasets_on_raster_band_index", using: :btree
  add_index "raster_datasets", ["raster_dataset_group_id"], name: "index_raster_datasets_on_raster_dataset_group_id", using: :btree

  create_table "raster_groups", force: true do |t|
    t.string   "name"
    t.string   "mnemonic",       limit: 64
    t.integer  "display_order"
    t.integer  "parent_id",      limit: 8
    t.boolean  "hidden"
    t.datetime "created_at",                default: "now()"
    t.datetime "updated_at",                default: "now()"
    t.string   "sort_operation", limit: 64
  end

  add_index "raster_groups", ["display_order"], name: "index_raster_groups_on_display_order", using: :btree
  add_index "raster_groups", ["name"], name: "index_raster_groups_on_name", using: :btree
  add_index "raster_groups", ["parent_id"], name: "index_raster_groups_on_parent_id", using: :btree

  create_table "raster_groups_tags", id: false, force: true do |t|
    t.integer "raster_group_id", limit: 8
    t.integer "tag_id",          limit: 8
    t.integer "user_id",         limit: 8
    t.boolean "visible",                   default: true, null: false
  end

  create_table "raster_metadata", force: true do |t|
    t.text     "original_metadata"
    t.integer  "raster_variable_id", limit: 8
    t.datetime "created_at",                   default: "now()"
    t.datetime "updated_at",                   default: "now()"
  end

  add_index "raster_metadata", ["raster_variable_id"], name: "index_raster_metadata_on_raster_variable_id", using: :btree

  create_table "raster_operations", force: true do |t|
    t.string   "name",                limit: 32,                   null: false
    t.text     "description"
    t.integer  "raster_data_type_id", limit: 8
    t.datetime "created_at",                     default: "now()"
    t.datetime "updated_at",                     default: "now()"
    t.string   "opcode"
    t.boolean  "visible",                        default: true
    t.integer  "parent_id",           limit: 8
  end

  add_index "raster_operations", ["parent_id"], name: "index_raster_operations_on_parent_id", using: :btree

  create_table "raster_raster_variables", force: true do |t|
    t.integer  "raster_id",          limit: 8,                   null: false
    t.integer  "raster_variable_id", limit: 8,                   null: false
    t.datetime "created_at",                   default: "now()"
    t.datetime "updated_at",                   default: "now()"
  end

  add_index "raster_raster_variables", ["raster_id"], name: "index_raster_raster_variables_on_raster_id", using: :btree
  add_index "raster_raster_variables", ["raster_variable_id"], name: "index_raster_raster_variables_on_raster_variable_id", using: :btree

  create_table "raster_statistics", force: true do |t|
    t.integer  "geog_instance_id",   limit: 8
    t.integer  "raster_variable_id", limit: 8
    t.decimal  "mean",                         precision: 64, scale: 10
    t.decimal  "stddev",                       precision: 64, scale: 10
    t.integer  "cellcount",          limit: 8
    t.decimal  "summation",                    precision: 64, scale: 10
    t.decimal  "min",                          precision: 64, scale: 10
    t.decimal  "max",                          precision: 64, scale: 10
    t.datetime "created_at",                                             default: "now()"
    t.datetime "updated_at",                                             default: "now()"
  end

  add_index "raster_statistics", ["geog_instance_id"], name: "index_raster_statistics_on_geog_instance_id", using: :btree
  add_index "raster_statistics", ["raster_variable_id"], name: "index_raster_statistics_on_raster_variable_id", using: :btree

  create_table "raster_variable_classifications", force: true do |t|
    t.integer  "raster_variable_id",        limit: 8
    t.datetime "created_at",                          default: "now()"
    t.datetime "updated_at",                          default: "now()"
    t.integer  "mosaic_raster_variable_id", limit: 8
    t.integer  "grouping",                  limit: 8
  end

  add_index "raster_variable_classifications", ["mosaic_raster_variable_id"], name: "rvc_mosaic_raster_variable_id", using: :btree
  add_index "raster_variable_classifications", ["raster_variable_id"], name: "index_raster_variable_classifications_on_raster_variable_id", using: :btree

  create_table "raster_variable_group_memberships", force: true do |t|
    t.integer "raster_variable_id", limit: 8, null: false
    t.integer "raster_group_id",    limit: 8, null: false
  end

  add_index "raster_variable_group_memberships", ["id"], name: "index_raster_variable_group_memberships_on_id", using: :btree

  create_table "raster_variables", force: true do |t|
    t.string   "mnemonic",                          limit: 32,                                              null: false
    t.string   "long_mnemonic",                     limit: 128
    t.string   "label"
    t.integer  "raster_data_type_id",               limit: 8
    t.integer  "raster_dataset_id",                 limit: 8
    t.string   "filename"
    t.text     "description"
    t.integer  "begin_year"
    t.integer  "end_year"
    t.string   "units"
    t.boolean  "hidden"
    t.text     "original_metadata"
    t.datetime "created_at",                                                              default: "now()"
    t.datetime "updated_at",                                                              default: "now()"
    t.decimal  "mean",                                          precision: 64, scale: 10
    t.decimal  "stddev",                                        precision: 64, scale: 10
    t.decimal  "summation",                                     precision: 64, scale: 10
    t.integer  "cellcount",                         limit: 8
    t.integer  "cellcount_with_data",               limit: 8
    t.decimal  "min",                                           precision: 64, scale: 10
    t.decimal  "max",                                           precision: 64, scale: 10
    t.integer  "raster_group_id",                   limit: 8
    t.integer  "sort_weight",                                                             default: 0
    t.boolean  "show_in_ui",                                                              default: true
    t.integer  "area_reference_id",                 limit: 8
    t.integer  "second_area_reference_id",          limit: 8
    t.integer  "raster_variable_classification_id", limit: 8
    t.integer  "classification",                    limit: 8
  end

  add_index "raster_variables", ["area_reference_id"], name: "index_raster_variables_on_area_reference_id", using: :btree
  add_index "raster_variables", ["begin_year"], name: "index_raster_variables_on_begin_year", using: :btree
  add_index "raster_variables", ["end_year"], name: "index_raster_variables_on_end_year", using: :btree
  add_index "raster_variables", ["mnemonic"], name: "index_raster_variables_on_mnemonic", using: :btree
  add_index "raster_variables", ["raster_data_type_id"], name: "index_raster_variables_on_raster_data_type_id", using: :btree
  add_index "raster_variables", ["raster_dataset_id"], name: "index_raster_variables_on_raster_dataset_id", using: :btree
  add_index "raster_variables", ["raster_variable_classification_id"], name: "index_raster_variables_on_raster_variable_classification_id", using: :btree
  add_index "raster_variables", ["second_area_reference_id"], name: "index_raster_variables_on_second_area_reference_id", using: :btree

  create_table "raster_variables_topics", id: false, force: true do |t|
    t.integer "raster_variable_id", limit: 8, null: false
    t.integer "topic_id",           limit: 8, null: false
  end

  add_index "raster_variables_topics", ["raster_variable_id"], name: "index_raster_variables_topics_on_raster_variable_id", using: :btree
  add_index "raster_variables_topics", ["topic_id"], name: "index_raster_variables_topics_on_topic_id", using: :btree

# Could not dump table "rasters" because of following StandardError
#   Unknown type 'raster' for column 'rast'

  create_table "request_area_data_variables", force: true do |t|
    t.integer  "area_data_variable_id", limit: 8,                   null: false
    t.integer  "extract_request_id",    limit: 8,                   null: false
    t.datetime "created_at",                      default: "now()"
    t.datetime "updated_at",                      default: "now()"
    t.integer  "sample_geog_level_id",  limit: 8
  end

  add_index "request_area_data_variables", ["area_data_variable_id"], name: "index_request_area_data_variables_on_area_data_variable_id", using: :btree
  add_index "request_area_data_variables", ["extract_request_id"], name: "index_request_area_data_variables_on_extract_request_id", using: :btree

  create_table "request_geog_units", force: true do |t|
    t.integer  "extract_request_id", limit: 8,                   null: false
    t.integer  "geog_unit_id",       limit: 8,                   null: false
    t.datetime "created_at",                   default: "now()"
    t.datetime "updated_at",                   default: "now()"
  end

  create_table "request_raster_datasets", force: true do |t|
    t.integer  "raster_dataset_id",  limit: 8,                   null: false
    t.integer  "extract_request_id", limit: 8,                   null: false
    t.datetime "created_at",                   default: "now()"
    t.datetime "updated_at",                   default: "now()"
  end

  create_table "request_raster_variables", force: true do |t|
    t.integer  "raster_variable_id",   limit: 8,                   null: false
    t.integer  "extract_request_id",   limit: 8,                   null: false
    t.integer  "raster_operation_id",  limit: 8
    t.datetime "created_at",                     default: "now()"
    t.datetime "updated_at",                     default: "now()"
    t.integer  "sample_geog_level_id", limit: 8
    t.integer  "raster_dataset_id",    limit: 8
  end

  add_index "request_raster_variables", ["extract_request_id"], name: "index_request_raster_variables_on_extract_request_id", using: :btree
  add_index "request_raster_variables", ["raster_dataset_id"], name: "index_request_raster_variables_on_raster_dataset_id", using: :btree
  add_index "request_raster_variables", ["raster_operation_id"], name: "index_request_raster_variables_on_raster_operation_id", using: :btree
  add_index "request_raster_variables", ["raster_variable_id"], name: "index_request_raster_variables_on_raster_variable_id", using: :btree

  create_table "request_sample_geog_levels", force: true do |t|
    t.integer  "sample_geog_level_id", limit: 8,                   null: false
    t.integer  "extract_request_id",   limit: 8,                   null: false
    t.datetime "created_at",                     default: "now()"
    t.datetime "updated_at",                     default: "now()"
  end

  create_table "request_samples", force: true do |t|
    t.integer  "sample_id",               limit: 8,                                             null: false
    t.integer  "extract_request_id",      limit: 8,                                             null: false
    t.datetime "created_at",                                                  default: "now()"
    t.datetime "updated_at",                                                  default: "now()"
    t.decimal  "custom_sampling_ratio",             precision: 64, scale: 10
    t.integer  "first_household_sampled",                                     default: 1
  end

  create_table "request_terrapop_samples", force: true do |t|
    t.integer  "terrapop_sample_id", limit: 8,                   null: false
    t.integer  "extract_request_id", limit: 8,                   null: false
    t.datetime "created_at",                   default: "now()"
    t.datetime "updated_at",                   default: "now()"
  end

  create_table "request_variables", force: true do |t|
    t.integer  "variable_id",                  limit: 8,                   null: false
    t.integer  "extract_request_id",           limit: 8,                   null: false
    t.datetime "created_at",                             default: "now()"
    t.datetime "updated_at",                             default: "now()"
    t.integer  "attached_variable_pointer_id"
    t.boolean  "wants_attached"
    t.string   "general_detailed_selection",   limit: 1
    t.boolean  "wants_case_selection",                   default: false,   null: false
  end

  add_index "request_variables", ["extract_request_id"], name: "index_request_variables_on_extract_request_id", using: :btree
  add_index "request_variables", ["variable_id"], name: "index_request_variables_on_variable_id", using: :btree

  create_table "resolutions", force: true do |t|
    t.string   "label"
    t.datetime "created_at", default: "now()"
    t.datetime "updated_at", default: "now()"
  end

  create_table "sample_designs", force: true do |t|
    t.string   "filename",   limit: 1024
    t.text     "document",                                  null: false
    t.integer  "country_id", limit: 8,                      null: false
    t.datetime "created_at",              default: "now()"
    t.datetime "updated_at",              default: "now()"
  end

  add_index "sample_designs", ["country_id"], name: "index_sample_designs_on_country_id", using: :btree

  create_table "sample_detail_fields", force: true do |t|
    t.integer  "sample_detail_group_id"
    t.string   "name"
    t.string   "label"
    t.integer  "order"
    t.text     "help_text"
    t.datetime "created_at",             default: "now()"
    t.datetime "updated_at",             default: "now()"
    t.boolean  "summary_only"
  end

  create_table "sample_detail_groups", force: true do |t|
    t.string  "name"
    t.integer "order"
  end

  create_table "sample_detail_values", force: true do |t|
    t.integer  "sample_id"
    t.integer  "sample_detail_field_id"
    t.text     "value"
    t.datetime "created_at",             default: "now()"
    t.datetime "updated_at",             default: "now()"
  end

  add_index "sample_detail_values", ["sample_id", "sample_detail_field_id"], name: "idx_sample_field", unique: true, using: :btree

  create_table "sample_geog_levels", force: true do |t|
    t.integer  "country_level_id",    limit: 8
    t.integer  "terrapop_sample_id",  limit: 8
    t.string   "label"
    t.string   "code",                limit: 10
    t.string   "internal_code",       limit: 128
    t.integer  "geolink_variable_id", limit: 8
    t.datetime "created_at",                      default: "now()"
    t.datetime "updated_at",                      default: "now()"
    t.string   "nhgis_dat_file",      limit: 254
    t.string   "nhgis_dat_file_m",    limit: 254
    t.integer  "gisjoin1_start",      limit: 8
    t.integer  "gisjoin1_width",      limit: 8
    t.integer  "gisjoin2_start",      limit: 8
    t.integer  "gisjoin2_width",      limit: 8
  end

  add_index "sample_geog_levels", ["code"], name: "index_sample_geog_levels_on_code", unique: true, using: :btree

  create_table "sample_level_area_data_variables", force: true do |t|
    t.integer  "area_data_variable_id", limit: 8
    t.integer  "terrapop_sample_id",    limit: 8
    t.integer  "sample_geog_level_id",  limit: 8
    t.datetime "created_at",                      default: "now()"
    t.datetime "updated_at",                      default: "now()"
    t.integer  "start_pos",             limit: 8
    t.integer  "width",                 limit: 8
  end

  add_index "sample_level_area_data_variables", ["area_data_variable_id"], name: "index_sample_level_area_data_variables_on_area_data_variable_id", using: :btree
  add_index "sample_level_area_data_variables", ["terrapop_sample_id", "sample_geog_level_id"], name: "sladv_terrapop_sample_sample_geog_level_index", using: :btree

  create_table "sample_level_area_variable_constructions", id: false, force: true do |t|
    t.integer "sample_level_area_data_variable_id", limit: 8
    t.integer "variable_id",                        limit: 8
  end

  create_table "sample_variables", force: true do |t|
    t.integer  "variable_id", limit: 8
    t.integer  "sample_id",   limit: 8
    t.integer  "universe_id", limit: 8
    t.string   "anchor_form"
    t.string   "anchor_inst"
    t.datetime "created_at",            default: "now()"
    t.datetime "updated_at",            default: "now()"
  end

  add_index "sample_variables", ["sample_id"], name: "index_sample_variables_on_sample_id", using: :btree
  add_index "sample_variables", ["universe_id"], name: "index_sample_variables_on_universe_id", using: :btree
  add_index "sample_variables", ["variable_id"], name: "index_sample_variables_on_variable_id", using: :btree

  create_table "samples", force: true do |t|
    t.string   "name"
    t.integer  "country_id",         limit: 8
    t.integer  "year"
    t.decimal  "density",                        precision: 6, scale: 3
    t.string   "note"
    t.integer  "h_records"
    t.integer  "p_records"
    t.boolean  "is_old"
    t.boolean  "use_suffix"
    t.string   "data_file_name"
    t.integer  "hide_status"
    t.string   "sample_value"
    t.string   "list"
    t.string   "short_description"
    t.string   "display_group"
    t.boolean  "is_puerto_rico"
    t.integer  "freq_order"
    t.string   "medium_description"
    t.string   "data_provider",      limit: 512
    t.string   "long_description"
    t.integer  "display_order"
    t.boolean  "is_sda"
    t.integer  "month"
    t.string   "fingerprint_sha512", limit: 128
    t.datetime "created_at",                                             default: "now()"
    t.datetime "updated_at",                                             default: "now()"
    t.integer  "filesize",           limit: 8,                           default: 0,       null: false
    t.boolean  "restricted",                                             default: true
  end

  create_table "samples_tags", id: false, force: true do |t|
    t.integer "sample_id", limit: 8
    t.integer "tag_id",    limit: 8
    t.integer "user_id",   limit: 8
    t.boolean "visible",             default: true, null: false
  end

  create_table "sessions", force: true do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", unique: true, using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "spatial_ref_sys", primary_key: "srid", force: true do |t|
    t.string  "auth_name", limit: 256
    t.integer "auth_srid"
    t.string  "srtext",    limit: 2048
    t.string  "proj4text", limit: 2048
  end

  create_table "status_definitions", force: true do |t|
    t.string   "status",     limit: 64
    t.datetime "created_at",            default: "now()"
    t.datetime "updated_at",            default: "now()"
  end

  create_table "system_statistics", force: true do |t|
    t.string   "key",        limit: 64,                                             null: false
    t.decimal  "value",                 precision: 64, scale: 10
    t.datetime "created_at",                                      default: "now()"
    t.datetime "updated_at",                                      default: "now()"
  end

  add_index "system_statistics", ["key"], name: "index_system_statistics_on_key", unique: true, using: :btree

  create_table "tags", force: true do |t|
    t.string   "tag"
    t.boolean  "visible",    default: true,    null: false
    t.datetime "created_at", default: "now()"
    t.datetime "updated_at", default: "now()"
  end

  create_table "terrapop_raster_summary_caches", force: true do |t|
    t.integer  "sample_geog_level_id",  limit: 8
    t.integer  "raster_variable_id",    limit: 8
    t.text     "raster_operation_name"
    t.integer  "geog_instance_id",      limit: 8
    t.text     "geog_instance_label"
    t.decimal  "geog_instance_code",              precision: 20, scale: 0
    t.text     "raster_mnemonic"
    t.decimal  "boundary_area",                   precision: 64, scale: 10
    t.decimal  "summary_value",                   precision: 20, scale: 4
    t.datetime "created_at",                                                default: "now()"
    t.datetime "updated_at",                                                default: "now()"
    t.decimal  "raster_area",                     precision: 64, scale: 10
    t.boolean  "has_area_reference",                                        default: false
    t.integer  "band_index",            limit: 8,                           default: 1
    t.integer  "raster_dataset_id",     limit: 8
  end

  add_index "terrapop_raster_summary_caches", ["raster_dataset_id"], name: "index_terrapop_raster_summary_caches_on_raster_dataset_id", using: :btree
  add_index "terrapop_raster_summary_caches", ["raster_operation_name"], name: "index_terrapop_raster_summary_caches_on_raster_operation_name", using: :btree
  add_index "terrapop_raster_summary_caches", ["raster_variable_id"], name: "index_terrapop_raster_summary_caches_on_raster_variable_id", using: :btree
  add_index "terrapop_raster_summary_caches", ["sample_geog_level_id", "raster_variable_id", "raster_operation_name"], name: "terrapop_raster_summary_caches_triplet_idx", using: :btree
  add_index "terrapop_raster_summary_caches", ["sample_geog_level_id"], name: "index_terrapop_raster_summary_caches_on_sample_geog_level_id", using: :btree

  create_table "terrapop_samples", force: true do |t|
    t.integer  "sample_id",          limit: 8
    t.string   "label"
    t.text     "description"
    t.datetime "created_at",                     default: "now()"
    t.datetime "updated_at",                     default: "now()"
    t.text     "local_title"
    t.text     "census_agency"
    t.integer  "country_id",         limit: 8
    t.integer  "year",               limit: 8
    t.string   "short_country_name", limit: 4
    t.integer  "nhgis_dataset_id",   limit: 8
    t.integer  "begin_year"
    t.integer  "end_year"
    t.string   "source_project",     limit: 254
    t.string   "short_label",                    default: ""
    t.boolean  "boundaries_only",                default: false
  end

  add_index "terrapop_samples", ["country_id"], name: "index_terrapop_samples_on_country_id", using: :btree
  add_index "terrapop_samples", ["short_country_name"], name: "index_terrapop_samples_on_short_country_name", using: :btree
  add_index "terrapop_samples", ["source_project"], name: "index_terrapop_samples_on_source_project", using: :btree
  add_index "terrapop_samples", ["year"], name: "index_terrapop_samples_on_year", using: :btree

  create_table "terrapop_samples_tags", id: false, force: true do |t|
    t.integer "terrapop_sample_id", limit: 8
    t.integer "tag_id",             limit: 8
    t.integer "user_id",            limit: 8
    t.boolean "visible",                      default: true, null: false
  end

  create_table "terrapop_settings", force: true do |t|
    t.hstore   "data"
    t.datetime "created_at", default: "now()"
    t.datetime "updated_at", default: "now()"
    t.string   "name",                         null: false
  end

  add_index "terrapop_settings", ["name"], name: "index_terrapop_settings_on_name", unique: true, using: :btree

  create_table "topics", force: true do |t|
    t.string   "name",       limit: 128,                   null: false
    t.string   "code",       limit: 16,                    null: false
    t.datetime "created_at",             default: "now()"
    t.datetime "updated_at",             default: "now()"
  end

  create_table "topics_variables", id: false, force: true do |t|
    t.integer "variable_id", limit: 8, null: false
    t.integer "topic_id",    limit: 8, null: false
  end

  add_index "topics_variables", ["topic_id"], name: "index_topics_variables_on_topic_id", using: :btree
  add_index "topics_variables", ["variable_id"], name: "index_topics_variables_on_variable_id", using: :btree

  create_table "ui_text_snippets", force: true do |t|
    t.text     "key_text"
    t.text     "text_snippet"
    t.datetime "created_at",   default: "now()"
    t.datetime "updated_at",   default: "now()"
  end

  add_index "ui_text_snippets", ["key_text"], name: "index_ui_text_snippets_on_key_text", using: :btree

  create_table "universes", force: true do |t|
    t.string   "sample_statement"
    t.text     "universe_statement"
    t.boolean  "display_sample_statement"
    t.boolean  "make_sample_statement"
    t.datetime "created_at",               default: "now()"
    t.datetime "updated_at",               default: "now()"
  end

  create_table "user_roles", force: true do |t|
    t.string   "role",       limit: 32,                   null: false
    t.datetime "created_at",            default: "now()"
    t.datetime "updated_at",            default: "now()"
  end

  create_table "users", force: true do |t|
    t.string   "firstname",                       limit: 128, default: "",      null: false
    t.string   "lastname",                        limit: 128, default: "",      null: false
    t.string   "email",                                       default: "",      null: false
    t.string   "encrypted_password",              limit: 256, default: "",      null: false
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "confirmation_token"
    t.string   "unconfirmed_email"
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                               default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "failed_attempts",                             default: 0
    t.string   "unlock_token"
    t.string   "authentication_token"
    t.integer  "user_role_id",                    limit: 8
    t.datetime "locked_at"
    t.datetime "created_at",                                  default: "now()"
    t.datetime "updated_at",                                  default: "now()"
    t.boolean  "microdata_access_allowed",                    default: false
    t.boolean  "microdata_access_requested",                  default: false
    t.datetime "microdata_access_requested_date"
    t.datetime "microdata_access_approved_date"
    t.integer  "ipumsi_user_id",                  limit: 8
    t.hstore   "data"
    t.string   "address_line_1",                  limit: 128
    t.string   "address_line_2",                  limit: 128
    t.string   "address_line_3",                  limit: 128
    t.string   "city",                            limit: 128
    t.string   "state",                           limit: 64
    t.string   "postal_code",                     limit: 32
    t.string   "registration_country",            limit: 128
    t.string   "country_of_origin",               limit: 256
    t.string   "personal_phone",                  limit: 64
    t.text     "explain_no_affiliation"
    t.string   "institution",                     limit: 128
    t.string   "inst_email",                      limit: 128
    t.string   "inst_web",                        limit: 128
    t.string   "inst_boss",                       limit: 128
    t.string   "inst_address_line_1",             limit: 128
    t.string   "inst_address_line_2",             limit: 128
    t.string   "inst_address_line_3",             limit: 128
    t.string   "inst_city",                       limit: 128
    t.string   "inst_state",                      limit: 64
    t.string   "inst_postal_code",                limit: 32
    t.string   "inst_registration_country",       limit: 128
    t.string   "inst_phone",                      limit: 64
    t.boolean  "has_ethics"
    t.string   "ethical_board",                   limit: 128
    t.string   "field",                           limit: 128
    t.string   "academic_status",                 limit: 128
    t.string   "research_type",                   limit: 64
    t.text     "research_description"
    t.boolean  "health_research"
    t.text     "funder"
    t.boolean  "opt_in"
    t.boolean  "no_fees"
    t.boolean  "cite"
    t.boolean  "send_copy"
    t.boolean  "data_only"
    t.boolean  "good_not_evil"
    t.boolean  "no_redistribution"
    t.boolean  "learning_only"
    t.boolean  "non_commercial"
    t.boolean  "confidentiality"
    t.boolean  "secure_data"
    t.boolean  "scholarly_publication"
    t.boolean  "discipline"
    t.datetime "ipumsi_request_email_sent_at"
    t.string   "api_key",                         limit: 256
    t.boolean  "institutional_affiliation"
    t.datetime "deactivated_at"
    t.datetime "deleted_at"
    t.string   "ipumsi_salt",                     limit: 40
    t.string   "ipumsi_crypted_password",         limit: 40
    t.boolean  "hide_nhgis_datasets",                         default: true
    t.datetime "microdata_access_expired_date"
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", unique: true, using: :btree
  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["data"], name: "users_gin_data", using: :gin
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["ipumsi_user_id"], name: "index_users_on_ipumsi_user_id", using: :btree
  add_index "users", ["microdata_access_allowed"], name: "index_users_on_microdata_access_allowed", using: :btree
  add_index "users", ["microdata_access_requested"], name: "index_users_on_microdata_access_requested", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["unconfirmed_email"], name: "index_users_on_unconfirmed_email", using: :btree
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree

  create_table "variable_availability_caches", force: true do |t|
    t.integer  "variable_id", limit: 8,                   null: false
    t.text     "json"
    t.datetime "created_at",            default: "now()"
    t.datetime "updated_at",            default: "now()"
  end

  add_index "variable_availability_caches", ["variable_id"], name: "index_variable_availability_caches_on_variable_id", using: :btree

  create_table "variable_groups", force: true do |t|
    t.string   "name"
    t.string   "abbrev"
    t.string   "rectype"
    t.integer  "parent_id",  limit: 8
    t.integer  "order",      limit: 8
    t.datetime "created_at",           default: "now()"
    t.datetime "updated_at",           default: "now()"
  end

  add_index "variable_groups", ["parent_id"], name: "index_variable_groups_on_parent_id", using: :btree

  create_table "variable_sources", force: true do |t|
    t.integer  "makes",      limit: 8,                   null: false
    t.integer  "is_made_of", limit: 8,                   null: false
    t.datetime "created_at",           default: "now()"
    t.datetime "updated_at",           default: "now()"
  end

  add_index "variable_sources", ["is_made_of"], name: "index_variable_sources_on_is_made_of", using: :btree
  add_index "variable_sources", ["makes"], name: "index_variable_sources_on_makes", using: :btree

  create_table "variables", force: true do |t|
    t.string   "mnemonic",                     limit: 32
    t.string   "long_mnemonic",                limit: 64
    t.string   "label"
    t.integer  "variable_group_id",            limit: 8
    t.string   "record_type",                  limit: 1
    t.boolean  "is_svar"
    t.integer  "sample_id",                    limit: 8
    t.boolean  "is_general_detailed"
    t.boolean  "is_old"
    t.boolean  "is_dq_flag"
    t.text     "description"
    t.text     "general_comparability"
    t.text     "ipums_comparability"
    t.boolean  "questionnaires"
    t.text     "manual_codes_display"
    t.boolean  "nontabulated"
    t.integer  "hide_extract_status"
    t.string   "case_select_type"
    t.integer  "default_order"
    t.integer  "column_start"
    t.integer  "column_width"
    t.integer  "general_column_width"
    t.boolean  "show_questionnaires_link"
    t.integer  "hide_status"
    t.string   "data_type"
    t.integer  "preselect_status"
    t.integer  "implied_decimal_places"
    t.boolean  "replicate_weight"
    t.integer  "original_record_type_id"
    t.string   "nhis_mnemonic"
    t.boolean  "do_not_attach"
    t.boolean  "is_sda"
    t.boolean  "is_preliminary"
    t.boolean  "constructed"
    t.string   "original_name"
    t.datetime "created_at",                              default: "now()"
    t.datetime "updated_at",                              default: "now()"
    t.integer  "replicate_weight_variable_id", limit: 8
  end

  add_index "variables", ["default_order"], name: "index_variables_on_default_order", using: :btree
  add_index "variables", ["is_svar"], name: "index_variables_on_is_svar", using: :btree
  add_index "variables", ["mnemonic"], name: "index_variables_on_mnemonic", using: :btree
  add_index "variables", ["sample_id"], name: "index_variables_on_sample_id", using: :btree
  add_index "variables", ["variable_group_id"], name: "index_variables_on_variable_group_id", using: :btree

end
