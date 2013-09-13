class ReencryptDbUrls < ActiveRecord::Migration
  def change
    Account.find_each do |account|
      account.db_url = account.decrypted_db_url
      account.save
    end
  end
end
