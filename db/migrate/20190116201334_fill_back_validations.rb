class FillBackValidations < ActiveRecord::Migration[5.1]
  def up
    TableConfiguration.reset_column_information
    Account.not_deleted.where.not(encrypted_db_url: nil).find_each do |account|
      begin
        puts account.id
        generic = Generic.new account
        generic.tables.each do |table|
          resource = Resource.new generic, table
          next unless resource.datas && resource.datas[:validations].present?
          account.table_configurations.find_or_create_by(table: table).update! validations: resource.datas[:validations]
          resource.save
        end
        generic.cleanup
      rescue Sequel::DatabaseConnectionError, URI::InvalidURIError, Sequel::Error => e
        puts e
      end
    end
  end
end
