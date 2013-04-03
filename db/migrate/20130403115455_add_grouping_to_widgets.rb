class AddGroupingToWidgets < ActiveRecord::Migration
  def change
    add_column :widgets, :grouping, :string
  end
end
