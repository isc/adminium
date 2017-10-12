class CreateTableConfigurations < ActiveRecord::Migration[5.0]
  def change
    create_table :table_configurations do |t|
      t.references :account, index: true, foreign_key: true
      t.string :table
      t.jsonb :polymorphic_associations, default: []
      t.timestamps
    end
  end
end
