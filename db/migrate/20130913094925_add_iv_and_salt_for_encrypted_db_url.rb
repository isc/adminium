class AddIvAndSaltForEncryptedDbUrl < ActiveRecord::Migration
  def change
    add_column :accounts, :encrypted_db_url_salt, :string
    add_column :accounts, :encrypted_db_url_iv, :string
  end
end
