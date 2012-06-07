class CreateWidgets < ActiveRecord::Migration
  def change
    create_table :widgets do |t|
      t.string :table
      t.string :advanced_search
      t.string :order
      t.string :columns
      t.integer :account_id

      t.timestamps
    end
  end
end
