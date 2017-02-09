class ChangeEncryptedDbUrlTypeToText < ActiveRecord::Migration
  def change
    change_column :accounts, :encrypted_db_url, :text
  end
end
