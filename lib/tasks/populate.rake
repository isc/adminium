task :reset_adminium_demo_settings => :environment do
  account_id = ENV['DEMO_ACCOUNT_ID']
  return if account_id.nil?
  account = Account.find(account_id)
  account.widgets.delete_all

  REDIS.del "account:#{account_id}:settings:Payment", "account:#{account_id}:settings:Users", "account:#{account_id}:settings:Partners"

  account.time_chart_widgets.create! table: 'payments', columns: "created_at", grouping: "dow"
  account.table_widgets.create! table: 'payments', order: 'amount desc'
  account.table_widgets.create! table: 'users', order: 'created_at desc'
  account.table_widgets.create! table: 'partners'

  payments_settings = Generic.new(account).table('payments').settings
  payments_settings.enum_values = [{"column_name"=>"status", "values"=>{"4"=>{"color"=>"#999999", "label"=>"refunded"}, "1"=>{"color"=>"#33CC66", "label"=>"completed"}, "0"=>{"color"=>"#3366FF", "label"=>"in progress"}, "3"=>{"color"=>"#CC3300", "label"=>"failed"}, "2"=>{"color"=>"#FF9900", "label"=>"verified"}}}]
  payments_settings.columns[:listing]=["id", "user.email", "user_id", "amount", "status", "created_at", "updated_at"]
  payments_settings.save
  payments_settings.update_column_options 'amount', {"rename"=>"", "number_separator"=>"", "number_delimiter"=>"", "number_unit"=>"$", "number_precision"=>""}
  payments_settings.update_column_options "created_at", {"rename"=>"", "format"=>"time_ago_in_words"}

  users_settings = Generic.new(account).table('users').settings
  users_settings.label_column = 'pseudo'
  users_settings.columns[:listing] = ["id", "pseudo", "email", "partner_id", "has_many/payments"]
  users_settings.save

  partners_settings = Generic.new(account).table('partners').settings
  partners_settings.columns[:listing] = ["id", "name", "has_many/users", "created_at"]
  partners_settings.label_column = 'name'
  partners_settings.save
end
