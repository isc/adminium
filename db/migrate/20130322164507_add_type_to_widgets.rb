class AddTypeToWidgets < ActiveRecord::Migration
  def change
    add_column :widgets, :type, :string
    Widget.update_all "type = 'TableWidget'"
  end
end
