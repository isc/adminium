class AddDefaultOrderToTableConfigurations < ActiveRecord::Migration[7.0]
  def change
    add_column :table_configurations, :default_order, :string
  end
end
