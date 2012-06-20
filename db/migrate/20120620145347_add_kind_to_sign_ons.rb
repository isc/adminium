class AddKindToSignOns < ActiveRecord::Migration
  def change
    add_column :sign_ons, :kind, :integer

  end
end
