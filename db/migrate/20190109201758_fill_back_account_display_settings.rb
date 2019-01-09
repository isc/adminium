class FillBackAccountDisplaySettings < ActiveRecord::Migration[5.1]
  def change
    Account.not_deleted.find_each do |account|
      global = Resource::Global.new account.id
      account.update_columns per_page: global.per_page,
        date_format: global.date_format, datetime_format: global.datetime_format
    end
  end
end
