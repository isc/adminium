class AddEnumValuesToTableConfigurations < ActiveRecord::Migration[7.0]
  def change
    add_column :table_configurations, :enum_values, :json
  end
end
