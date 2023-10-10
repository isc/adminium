class AddSignCountToCredentials < ActiveRecord::Migration[5.2]
  def change
    add_column :credentials, :sign_count, :bigint, default: 0, null: false
  end
end
