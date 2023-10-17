class RemoveColumnAccountsPlanMigrations < ActiveRecord::Migration[5.2]
  def change
    remove_column :accounts, :plan_migrations
  end
end
