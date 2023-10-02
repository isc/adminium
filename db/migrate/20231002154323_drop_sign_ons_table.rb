class DropSignOnsTable < ActiveRecord::Migration[5.2]
  def change
    drop_table :sign_ons
  end
end
