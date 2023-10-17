class RemoveTotalHerokuAppsFromUsers < ActiveRecord::Migration[5.2]
  def change
    remove_column :users, :total_heroku_apps
  end
end
