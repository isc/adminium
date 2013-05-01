class AddUserIdToSignOns < ActiveRecord::Migration
  def change
    add_column :sign_ons, :user_id, :integer
  end
end
