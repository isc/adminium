class DropAppProfiles < ActiveRecord::Migration[5.0]
  def change
    drop_table :app_profiles
  end
end
