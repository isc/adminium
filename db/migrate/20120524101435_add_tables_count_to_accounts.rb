class AddTablesCountToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :tables_count, :integer

  end
end
