class ReencryptDbUrls < ActiveRecord::Migration
  def change
    Account.reset_column_information
    Account.where.not(encrypted_db_url: [nil, '']).find_each do |account|
      account.db_url = account.decrypted_db_url
      account.save validate: false
    end
  end
end
