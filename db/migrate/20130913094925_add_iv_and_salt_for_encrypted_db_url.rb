class AddIvAndSaltForEncryptedDbUrl < ActiveRecord::Migration
  def change
    add_column :accounts, :encrypted_password_salt, :string
    add_column :accounts, :encrypted_password_iv, :string
  end
end
