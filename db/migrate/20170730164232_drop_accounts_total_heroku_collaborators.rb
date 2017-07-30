class DropAccountsTotalHerokuCollaborators < ActiveRecord::Migration[5.0]
  def change
    remove_column :accounts, :total_heroku_collaborators
  end
end
