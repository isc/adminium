class AddExportColSepToTableConfigurations < ActiveRecord::Migration[6.1]
  def change
    add_column :table_configurations, :export_col_sep, :string
  end
end
