class CreateSignOns < ActiveRecord::Migration
  def change
    create_table :sign_ons do |t|
      t.integer :account_id
      t.string :plan
      t.string :remote_ip

      t.timestamps
    end
  end
end
