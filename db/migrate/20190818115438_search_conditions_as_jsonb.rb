class SearchConditionsAsJsonb < ActiveRecord::Migration[5.2]
  def change
    change_column :searches, :conditions, :jsonb
  end
end
