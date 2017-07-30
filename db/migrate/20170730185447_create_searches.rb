class CreateSearches < ActiveRecord::Migration[5.0]
  def change
    create_table :searches do |t|
      t.string :name
      t.string :table
      t.references :account, foreign_key: true
      t.json :conditions

      t.timestamps
    end
  end
end
