class AddDisplaySettingsToAccounts < ActiveRecord::Migration[5.1]
  def change
    add_column :accounts, :per_page, :integer, default: 25, null: false
    add_column :accounts, :date_format, :string, default: 'long', null: false
    add_column :accounts, :datetime_format, :string, default: 'long', null: false
    add_column :accounts, :export_col_sep, :string, default: ',', null: false
    add_column :accounts, :export_skip_header, :boolean, default: false, null: false
  end
end
