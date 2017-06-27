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

ActiveRecord::Schema.define(version: 20170627225244) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string   "plan"
    t.string   "api_key"
    t.string   "heroku_id"
    t.string   "callback_url"
    t.string   "name"
    t.string   "owner_email"
    t.text     "encrypted_db_url"
    t.string   "adapter"
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.string   "heroku_uuid"
  end

  create_table "app_profiles", force: :cascade do |t|
    t.text     "app_infos"
    t.text     "addons_infos"
    t.integer  "account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "collaborators", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "account_id"
    t.string   "email",                            null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_administrator", default: false, null: false
    t.string   "kind"
    t.index ["account_id"], name: "index_collaborators_on_account_id", using: :btree
    t.index ["user_id"], name: "index_collaborators_on_user_id", using: :btree
  end

  create_table "collaborators_roles", id: false, force: :cascade do |t|
    t.integer "role_id"
    t.integer "collaborator_id"
    t.index ["role_id", "collaborator_id"], name: "index_collaborators_roles_on_role_id_and_collaborator_id", using: :btree
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name"
    t.integer  "account_id"
    t.text     "permissions"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sign_ons", force: :cascade do |t|
    t.integer  "account_id"
    t.string   "plan"
    t.string   "remote_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "kind"
    t.integer  "user_id"
  end

  create_table "statistics", primary_key: ["account_id", "action"], force: :cascade do |t|
    t.integer  "account_id",             null: false
    t.string   "action",                 null: false
    t.integer  "value",      default: 0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "provider"
    t.string   "uid"
    t.string   "name"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "total_heroku_apps"
  end

  create_table "widgets", force: :cascade do |t|
    t.string   "table"
    t.string   "advanced_search"
    t.string   "order"
    t.string   "columns"
    t.integer  "account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type"
    t.string   "grouping"
  end

end
