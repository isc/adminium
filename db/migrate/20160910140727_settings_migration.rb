class SettingsMigration < ActiveRecord::Migration
  def change
    Account.settings_migration
  end
end
