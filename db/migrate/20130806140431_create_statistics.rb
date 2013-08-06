class CreateStatistics < ActiveRecord::Migration
  def change
    create_table :statistics, force: true, id: false do |t|
      t.integer :account_id, null: false
      t.string :action, null: false
      t.integer :value, default: 0, null: false
      t.timestamps
    end
    execute "alter table statistics add primary key(account_id,action)"
    #add_index :statistics, [:account_id, :action]
  end
end
