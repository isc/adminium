class AddTimeZoneToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :application_time_zone, :string, null: false, default: 'UTC'
    add_column :accounts, :database_time_zone, :string, null: false, default: 'UTC'
  end
end
