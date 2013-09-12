class CreateAppProfiles < ActiveRecord::Migration
  def change
    create_table :app_profiles do |t|
      t.text :app_infos, :addons_infos
      t.integer :account_id
      t.timestamps
    end
  end
end
