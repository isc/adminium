class AddLastTipShowOnAccounts < ActiveRecord::Migration

  def up
    add_column :accounts, :last_tip_at, :datetime
    add_column :accounts, :last_tip_identifier, :string
    add_column :accounts, :tips_opt_in, :boolean, default: true
    Account.update_all "last_tip_identifier = 'welcome'"
  end

  def down
  end
end