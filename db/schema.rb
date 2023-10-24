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

ActiveRecord::Schema[7.0].define(version: 2023_10_24_190209) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "name"
    t.text "encrypted_db_url"
    t.string "adapter"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.datetime "last_tip_at", precision: nil
    t.string "last_tip_identifier"
    t.boolean "tips_opt_in", default: true
    t.string "application_time_zone", default: "UTC", null: false
    t.string "database_time_zone", default: "UTC", null: false
    t.string "encrypted_db_url_salt"
    t.string "encrypted_db_url_iv"
    t.integer "per_page", default: 25, null: false
    t.string "date_format", default: "long", null: false
    t.string "datetime_format", default: "long", null: false
  end

  create_table "collaborators", force: :cascade do |t|
    t.integer "user_id"
    t.integer "account_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "is_administrator", default: false, null: false
    t.string "email"
    t.string "token", null: false
    t.index ["account_id"], name: "index_collaborators_on_account_id"
    t.index ["user_id"], name: "index_collaborators_on_user_id"
  end

  create_table "collaborators_roles", id: false, force: :cascade do |t|
    t.integer "role_id"
    t.integer "collaborator_id"
    t.index ["role_id", "collaborator_id"], name: "index_collaborators_roles_on_role_id_and_collaborator_id"
  end

  create_table "credentials", force: :cascade do |t|
    t.string "external_id"
    t.string "public_key"
    t.bigint "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "sign_count", default: 0, null: false
    t.index ["external_id"], name: "index_credentials_on_external_id", unique: true
    t.index ["user_id"], name: "index_credentials_on_user_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.integer "account_id"
    t.text "permissions"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "searches", force: :cascade do |t|
    t.string "name"
    t.string "table"
    t.integer "account_id"
    t.jsonb "conditions"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["account_id"], name: "index_searches_on_account_id"
  end

  create_table "table_configurations", force: :cascade do |t|
    t.integer "account_id"
    t.string "table"
    t.jsonb "polymorphic_associations", default: []
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.jsonb "validations", default: [], null: false
    t.string "label_column"
    t.string "export_col_sep"
    t.boolean "export_skip_header"
    t.string "default_order"
    t.integer "per_page"
    t.json "enum_values"
    t.json "column_options", default: {}
    t.index ["account_id"], name: "index_table_configurations_on_account_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "webauthn_id"
    t.index ["webauthn_id"], name: "index_users_on_webauthn_id", unique: true
  end

  create_table "widgets", force: :cascade do |t|
    t.string "table"
    t.string "advanced_search"
    t.string "order"
    t.string "columns"
    t.integer "account_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "type"
    t.string "grouping"
  end

  add_foreign_key "searches", "accounts"
  add_foreign_key "table_configurations", "accounts"
end
