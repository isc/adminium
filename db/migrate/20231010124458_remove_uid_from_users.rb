class RemoveUidFromUsers < ActiveRecord::Migration[5.2]
  def change
    remove_column :users, :uid
  end
end
