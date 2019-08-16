task fetch_owner_emails: :environment do
  Account.fetch_missing_owner_emails
end

task reset_adminium_demo_account: :environment do
  account_id = ENV['DEMO_ACCOUNT_ID']
  return if account_id.nil?
  account = Account.find(account_id)
  account.widgets.delete_all

  REDIS.del "account:#{account_id}:settings:payments",
    "account:#{account_id}:settings:users", "account:#{account_id}:settings:partners"

  account.time_chart_widgets.create! table: 'payments', columns: 'created_at', grouping: 'dow'
  account.table_widgets.create! table: 'payments', order: 'amount desc'
  account.table_widgets.create! table: 'users', order: 'created_at desc'
  account.table_widgets.create! table: 'partners'
  generic = Generic.new(account)
  generic.db.tables.each { |table| generic.db.drop_table table unless table.in? %i(payments users partners) }
  payments_settings = Resource.new generic, :payments
  payments_settings.enum_values = [
    {'column_name' => 'status', 'values' => {
      '4' => {'color' => '#999999', 'label' => 'refunded'},
      '1' => {'color' => '#33CC66', 'label' => 'completed'},
      '0' => {'color' => '#3366FF', 'label' => 'in progress'},
      '3' => {'color' => '#CC3300', 'label' => 'failed'},
      '2' => {'color' => '#FF9900', 'label' => 'verified'}
    }}
  ]
  payments_settings.columns[:listing] = %w(id users.email user_id amount status created_at updated_at)
  payments_settings.save
  payments_settings.update_column_options 'amount', 'rename' => '', 'number_separator' => '', 'number_delimiter' => '',
    'number_unit' => '$', 'number_precision' => ''
  payments_settings.update_column_options 'created_at', 'rename' => '', 'format' => 'time_ago_in_words'

  users_settings = Resource.new generic, :users
  users_settings.label_column = 'pseudo'
  users_settings.columns[:listing] = %w(id pseudo email partner_id has_many/payments)
  users_settings.save

  partners_settings = Resource.new generic, :partners
  partners_settings.columns[:listing] = %w(id name has_many/users created_at)
  partners_settings.label_column = 'name'
  partners_settings.save
  generic.cleanup
end
