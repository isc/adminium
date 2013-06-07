class AddSourceToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :source, :string
  end
end
