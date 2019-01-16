class AddValidationsToTableConfigurations < ActiveRecord::Migration[5.1]
  def change
    add_column :table_configurations, :validations, :jsonb, null: false, default: []
  end
end
