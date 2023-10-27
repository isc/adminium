class AddColumnSelectionToTableConfiguration < ActiveRecord::Migration[7.0]
  def change
    add_column :table_configurations, :column_selection, :json, default: {}
  end
end
