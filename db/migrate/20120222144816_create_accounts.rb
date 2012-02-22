class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.string   "plan"
      t.string   "api_key"
      t.string   "heroku_id"
      t.string   "callback_url"
      t.string   "name"
      t.string   "owner_email"
      t.string   "encrypted_db_url"
      t.string   "adapter"
      t.timestamps
    end
  end
end
