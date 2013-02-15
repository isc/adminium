class AddTrackingOnAccounts < ActiveRecord::Migration
  def up
    add_column :accounts, :deleted_at, :datetime
    add_column :accounts, :plan_migrations, :text
  end

  def down
  end
end