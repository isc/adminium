class AddLabelColumnToTableConfigurations < ActiveRecord::Migration[5.2]
  def change
    add_column :table_configurations, :label_column, :string
  end
end
