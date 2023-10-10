class CreateCredentials < ActiveRecord::Migration[5.2]
  def change
    create_table :credentials do |t|
      t.string "external_id"
      t.string "public_key"
      t.bigint "user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["external_id"], name: "index_credentials_on_external_id", unique: true
      t.index ["user_id"], name: "index_credentials_on_user_id"
    end
  end
end
