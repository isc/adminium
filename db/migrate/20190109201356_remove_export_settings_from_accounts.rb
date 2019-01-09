class RemoveExportSettingsFromAccounts < ActiveRecord::Migration[5.1]
  def change
    remove_column :accounts, :export_col_sep
    remove_column :accounts, :export_skip_header
  end
end
