class FillBackLabelColumn < ActiveRecord::Migration[5.2]
  def change
    TableConfiguration.reset_column_information
    Account.not_deleted.where.not(encrypted_db_url: nil).find_each do |account|
      begin
        puts account.id
        generic = Generic.new account
        generic.tables.each do |table|
          resource = Resource.new generic, table
          next unless resource.datas && resource.datas[:label_column].present?
          account.table_configuration_for(table).update! label_column: resource.datas[:label_column]
          resource.save
        end
        generic.cleanup
      rescue Sequel::DatabaseConnectionError, URI::InvalidURIError, Sequel::Error => e
        puts e
      end
    end
  end
end
