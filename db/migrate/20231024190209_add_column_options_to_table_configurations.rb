class AddColumnOptionsToTableConfigurations < ActiveRecord::Migration[7.0]
  def change
    add_column :table_configurations, :column_options, :json, default: {}
  end
end
