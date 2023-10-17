class AddExportSkipHeaderToTableConfigurations < ActiveRecord::Migration[6.1]
  def change
    add_column :table_configurations, :export_skip_header, :boolean
  end
end
