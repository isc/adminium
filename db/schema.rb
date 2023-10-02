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

ActiveRecord::Schema.define(version: 2023_10_02_154323) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "plan"
    t.string "api_key"
    t.string "heroku_id"
    t.string "callback_url"
    t.string "name"
    t.string "owner_email"
    t.text "encrypted_db_url"
    t.string "adapter"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "tables_count"
    t.datetime "deleted_at"
    t.text "plan_migrations"
    t.datetime "last_tip_at"
    t.string "last_tip_identifier"
    t.boolean "tips_opt_in", default: true
    t.string "application_time_zone", default: "UTC", null: false
    t.string "database_time_zone", default: "UTC", null: false
    t.string "source"
    t.string "db_url_setup_method"
    t.string "encrypted_db_url_salt"
    t.string "encrypted_db_url_iv"
    t.string "heroku_uuid"
    t.integer "per_page", default: 25, null: false
    t.string "date_format", default: "long", null: false
    t.string "datetime_format", default: "long", null: false
  end

  create_table "collaborators", force: :cascade do |t|
    t.integer "user_id"
    t.integer "account_id"
    t.string "email", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "is_administrator", default: false, null: false
    t.string "kind"
    t.index ["account_id"], name: "index_collaborators_on_account_id"
    t.index ["user_id"], name: "index_collaborators_on_user_id"
  end

  create_table "collaborators_roles", id: false, force: :cascade do |t|
    t.integer "role_id"
    t.integer "collaborator_id"
    t.index ["role_id", "collaborator_id"], name: "index_collaborators_roles_on_role_id_and_collaborator_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.integer "account_id"
    t.text "permissions"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "searches", force: :cascade do |t|
    t.string "name"
    t.string "table"
    t.integer "account_id"
    t.jsonb "conditions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_searches_on_account_id"
  end

  create_table "table_configurations", force: :cascade do |t|
    t.integer "account_id"
    t.string "table"
    t.jsonb "polymorphic_associations", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "validations", default: [], null: false
    t.string "label_column"
    t.index ["account_id"], name: "index_table_configurations_on_account_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "provider"
    t.string "uid"
    t.string "name"
    t.string "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "total_heroku_apps"
  end

  create_table "widgets", force: :cascade do |t|
    t.string "table"
    t.string "advanced_search"
    t.string "order"
    t.string "columns"
    t.integer "account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "type"
    t.string "grouping"
  end

  add_foreign_key "searches", "accounts"
  add_foreign_key "table_configurations", "accounts"
end
