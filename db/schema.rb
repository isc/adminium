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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130830085606) do

  create_table "1121", :force => true do |t|
  end

  create_table "345342", :force => true do |t|
  end

  create_table "5675", :primary_key => "adasdads", :force => true do |t|
  end

  create_table "87", :force => true do |t|
  end

  create_table "9", :force => true do |t|
  end

  create_table "97", :primary_key => "9", :force => true do |t|
  end

  create_table "accounts", :force => true do |t|
    t.string   "plan"
    t.string   "api_key"
    t.string   "heroku_id"
    t.string   "callback_url"
    t.string   "name"
    t.string   "owner_email"
    t.string   "encrypted_db_url"
    t.string   "adapter"
    t.datetime "created_at",                                    :null => false
    t.datetime "updated_at",                                    :null => false
    t.integer  "tables_count"
    t.datetime "deleted_at"
    t.text     "plan_migrations"
    t.datetime "last_tip_at"
    t.string   "last_tip_identifier"
    t.boolean  "tips_opt_in",                :default => true
    t.string   "time_zone"
    t.string   "application_time_zone",      :default => "UTC", :null => false
    t.string   "database_time_zone",         :default => "UTC", :null => false
    t.string   "source"
    t.string   "db_url_setup_method"
    t.integer  "total_heroku_collaborators"
  end

  create_table "adadasdada", :force => true do |t|
  end

  create_table "adasdasdad", :force => true do |t|
  end

  create_table "adsasdasd", :force => true do |t|
  end

  create_table "app_profiles", :force => true do |t|
    t.text     "app_infos"
    t.text     "addons_infos"
    t.integer  "account_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "asdasd", :force => true do |t|
  end

  create_table "asdasda", :force => true do |t|
  end

  create_table "collaborators", :force => true do |t|
    t.integer  "user_id"
    t.integer  "account_id"
    t.string   "email",                               :null => false
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
    t.boolean  "is_administrator", :default => false, :null => false
    t.string   "kind"
  end

  add_index "collaborators", ["account_id"], :name => "index_collaborators_on_account_id"
  add_index "collaborators", ["user_id"], :name => "index_collaborators_on_user_id"

  create_table "collaborators_roles", :id => false, :force => true do |t|
    t.integer "role_id"
    t.integer "collaborator_id"
  end

  add_index "collaborators_roles", ["role_id", "collaborator_id"], :name => "index_roles_users_on_role_id_and_user_id"

  create_table "dadasasddds", :force => true do |t|
  end

  create_table "dddd", :force => true do |t|
  end

  create_table "lol", :force => true do |t|
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.integer  "account_id"
    t.text     "permissions"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "serieux", :primary_key => "ido", :force => true do |t|
    t.string "mais_lol"
  end

  create_table "sign_ons", :force => true do |t|
    t.integer  "account_id"
    t.string   "plan"
    t.string   "remote_ip"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "kind"
    t.integer  "user_id"
  end

  create_table "statistics", :id => false, :force => true do |t|
    t.integer  "account_id",                :null => false
    t.string   "action",                    :null => false
    t.integer  "value",      :default => 0, :null => false
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  create_table "testeur", :id => false, :force => true do |t|
    t.text "martini"
  end

  create_table "tests", :id => false, :force => true do |t|
    t.integer "lol0"
    t.integer "lol1"
    t.integer "lol2"
    t.integer "lol3"
  end

  create_table "tests1", :id => false, :force => true do |t|
    t.integer "id"
    t.float   "lol"
    t.integer "adasda"
  end

  create_table "tests111", :id => false, :force => true do |t|
    t.integer "id",   :null => false
    t.integer "test"
  end

  create_table "tests111aaa", :id => false, :force => true do |t|
    t.integer "id",     :null => false
    t.integer "asdasd"
  end

  create_table "tests2222", :force => true do |t|
  end

  create_table "tests34", :id => false, :force => true do |t|
    t.integer "id"
    t.text    "asdasdasd"
    t.integer "adadasdasdasad"
    t.integer "asdasdasdasd"
  end

  create_table "tests37", :id => false, :force => true do |t|
    t.integer  "id"
    t.datetime "daasd"
  end

  create_table "tests38", :id => false, :force => true do |t|
    t.integer "id"
    t.boolean "asdas"
  end

  create_table "testsadas23ads0", :id => false, :force => true do |t|
    t.integer "id",     :null => false
    t.integer "asdasd", :null => false
  end

  add_index "testsadas23ads0", ["asdasd"], :name => "testsadas23ads_asdasd_key", :unique => true
  add_index "testsadas23ads0", ["id"], :name => "testsadas23ads_id_key", :unique => true

  create_table "users", :force => true do |t|
    t.string   "provider"
    t.string   "uid"
    t.string   "name"
    t.string   "email"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.integer  "total_heroku_apps"
  end

  create_table "widgets", :force => true do |t|
    t.string   "table"
    t.string   "advanced_search"
    t.string   "order"
    t.string   "columns"
    t.integer  "account_id"
    t.datetime "created_at",      :null => false
    t.string   "type"
    t.string   "grouping"
  end

end
