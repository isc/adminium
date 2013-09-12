class AddSomeMoreStats < ActiveRecord::Migration
  def up
    add_column :users, :total_heroku_apps, :integer
    add_column :accounts, :total_heroku_collaborators, :integer
  end

  def down
    remove_column :users, :total_heroku_apps
    remove_column :accounts, :total_heroku_collaborators
  end
end