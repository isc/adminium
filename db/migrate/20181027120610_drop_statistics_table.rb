class DropStatisticsTable < ActiveRecord::Migration[5.1]
  def change
    drop_table :statistics
  end
end
