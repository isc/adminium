class AddPerPageToTableConfigurations < ActiveRecord::Migration[7.0]
  def change
    add_column :table_configurations, :per_page, :integer
  end
end
