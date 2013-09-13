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

ActiveRecord::Schema.define(version: 20130913105120) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: true do |t|
    t.string   "plan"
    t.string   "api_key"
    t.string   "heroku_id"
    t.string   "callback_url"
    t.string   "name"
    t.string   "owner_email"
    t.string   "encrypted_db_url"
    t.string   "adapter"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.integer  "tables_count"
    t.datetime "deleted_at"
    t.text     "plan_migrations"
    t.datetime "last_tip_at"
    t.string   "last_tip_identifier"
    t.boolean  "tips_opt_in",                default: true
    t.string   "application_time_zone",      default: "UTC", null: false
    t.string   "database_time_zone",         default: "UTC", null: false
    t.string   "source"
    t.string   "db_url_setup_method"
    t.integer  "total_heroku_collaborators"
    t.string   "encrypted_db_url_salt"
    t.string   "encrypted_db_url_iv"
    t.string   "decrypted_db_url"
  end

  create_table "app_profiles", force: true do |t|
    t.text     "app_infos"
    t.text     "addons_infos"
    t.integer  "account_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "collaborators", force: true do |t|
    t.integer  "user_id"
    t.integer  "account_id"
    t.string   "email",                            null: false
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.boolean  "is_administrator", default: false, null: false
    t.string   "kind"
  end

  add_index "collaborators", ["account_id"], name: "index_collaborators_on_account_id", using: :btree
  add_index "collaborators", ["user_id"], name: "index_collaborators_on_user_id", using: :btree

  create_table "collaborators_roles", id: false, force: true do |t|
    t.integer "role_id"
    t.integer "collaborator_id"
  end

  add_index "collaborators_roles", ["role_id", "collaborator_id"], name: "index_roles_users_on_role_id_and_user_id", using: :btree

  create_table "roles", force: true do |t|
    t.string   "name"
    t.integer  "account_id"
    t.text     "permissions"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "sign_ons", force: true do |t|
    t.integer  "account_id"
    t.string   "plan"
    t.string   "remote_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "kind"
    t.integer  "user_id"
  end

  create_table "statistics", id: false, force: true do |t|
    t.integer  "account_id",             null: false
    t.string   "action",                 null: false
    t.integer  "value",      default: 0, null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "users", force: true do |t|
    t.string   "provider"
    t.string   "uid"
    t.string   "name"
    t.string   "email"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.integer  "total_heroku_apps"
  end

  create_table "widgets", force: true do |t|
    t.string   "table"
    t.string   "advanced_search"
    t.string   "order"
    t.string   "columns"
    t.integer  "account_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "type"
    t.string   "grouping"
  end

end
