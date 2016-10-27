class Account < ActiveRecord::Base
  serialize :plan_migrations
  before_create :setup_api_key
  before_save :fill_adapter, :track_plan_migration
  has_many :collaborators
  has_many :users, through: :collaborators
  has_many :roles
  has_many :widgets, dependent: :destroy
  has_many :table_widgets
  has_many :time_chart_widgets
  has_many :pie_chart_widgets
  has_many :stat_chart_widgets
  has_many :sign_ons
  has_one :app_profile

  validates :db_url, format: %r{((mysql2?)|(postgres(ql)?)):\/\/.*}, allow_blank: true
  # fucked up "unless" below, but otherwise the tests are fucked up
  # likely because of the transactions being used in tests
  # and the fact that this validation causes a new connection to be established
  validate :db_url_validation unless Rails.env.test?

  attr_encrypted :db_url, key: (ENV['ENCRYPTION_KEY'] || 'shablagoo')

  scope :deleted, -> {where plan: Plan::DELETED}
  scope :not_deleted, -> {where.not plan: Plan::DELETED}

  TIPS = %w(basic_search editing enumerable export_import displayed_record advanced_search serialized relationships time_charts keyboard_shortcuts time_zones)

  class Plan
    PET_PROJECT = 'petproject'
    STARTUP = 'startup'
    ENTERPRISE = 'enterprise'
    COMPLIMENTARY = 'complimentary'
    DELETED = 'deleted'
  end

  def to_param
    api_key
  end

  def self.fetch_missing_owner_emails
    where(owner_email: nil).where.not(callback_url: nil).find_each do |account|
      begin
        auth = [HEROKU_MANIFEST['id'], HEROKU_MANIFEST['api']['password']].join(':')
        res = RestClient.get "https://#{auth}@api.heroku.com/vendor/apps/#{account.callback_url.split('/').last}"
        res = JSON.parse res
        account.update owner_email: res['owner_email']
        account.update name: res['name'] unless account.name?
      rescue RestClient::ResourceNotFound
        # not sure what to do with those accounts
      end
    end
  end

  def self.settings_migration
    Account.where.not(adapter: nil).where(deleted_at: nil).where('id > 5325').find_each do |account|
      begin
        puts "Account: #{account.id}"
        Rails.cache.delete "account:#{account.id}:associations"
        generic = Generic.new account
        generic.tables.each do |table|
          puts "Table: #{table}"
          resource = Resource::Base.new generic, table, no_columns_check: true
          resource.filters.values.each do |filter|
            filter.each do |condition|
              next unless condition['assoc'].present?
              info = resource.belongs_to_associations.detect {|info| info[:referenced_table] == condition['assoc'].to_sym}
              puts "replace #{condition['assoc']} by #{info[:foreign_key] if info}"
              next unless info
              condition['assoc'] = info[:foreign_key]
            end
          end
          resource.columns.each do |key, list|
            resource.columns[key] = list.map do |column|
              if column.to_s['.']
                # replace practices.formal_name by practice_id.formal_name for instance
                table, col = column.split('.')
                info = resource.belongs_to_associations.detect {|info| info[:referenced_table] == table.to_sym}
                res = "#{info[:foreign_key]}.#{col}" if info
                puts "column belongs_to: #{column} => #{res}"
                res || column
              elsif column.to_s.starts_with? 'has_many/'
                # replace has_many/appointments by has_many/appointments/agenda_id for instance
                _, table = column.to_s.split('/')
                info = resource.has_many_associations.detect {|info| info[:table] == table.to_sym}
                res = [column, info[:foreign_key]].join('/') if info
                puts "column has_many: #{column} => #{res}"
                res || column
              else
                column
              end
            end
          end
          resource.save
        end
      rescue Sequel::DatabaseConnectionError, URI::InvalidURIError, Sequel::DatabaseError
        puts "Failed to connect"
      end
    end
  end

  def valid_db_url?
    db_url.present?
  end

  def pet_project?
    plan == Plan::PET_PROJECT
  end

  def startup?
    plan == Plan::STARTUP
  end

  def free_plan?
    pet_project? || complimentary?
  end

  def enterprise?
    (plan == Plan::ENTERPRISE) || complimentary?
  end

  def complimentary?
    plan == Plan::COMPLIMENTARY
  end

  def upgrade_link
    # "https://api.heroku.com/v3/resources/adminium+#{{Plan::PET_PROJECT => Plan::STARTUP, Plan::STARTUP => Plan::ENTERPRISE}[plan]}?selected=#{name}"
    'https://addons.heroku.com/adminium'
  end

  def flag_as_deleted!
    update! db_url: nil, api_key: nil, plan: Plan::DELETED, deleted_at: Time.current
  end

  def displayed_next_tip
    return unless tips_opt_in
    tips = ['welcome'] + Account::TIPS
    tip = nil
    if last_tip_at.nil? || last_tip_at < 1.day.ago
      tip = tips[(tips.index(last_tip_identifier) || -1) + 1]
    end
    update! last_tip_at: Time.current, last_tip_identifier: tip if tip
    tip
  end

  def heroku_id_only
    heroku_id.match(/\d+/).to_s
  end

  def reactivate attributes
    update attributes.merge(deleted_at: nil, api_key: generate_api_key)
  end

  private

  def setup_api_key
    self.api_key = generate_api_key
  end

  def generate_api_key
    SecureRandom.hex[0..8]
  end

  def db_url_validation
    return if db_url.blank? || errors[:db_url].any?
    generic = Generic.new self
    generic.db.test_connection
    generic.cleanup
  rescue Sequel::Error, URI::InvalidURIError => e
    errors[:base] = e.message
  end

  def fill_adapter
    self.adapter = db_url.split(':').first if db_url? && encrypted_db_url_changed?
  end

  def track_plan_migration
    self.plan_migrations ||= []
    last_plan = plan_migrations.last[:plan] if plan_migrations.last
    if last_plan.nil? || last_plan != plan
      plan_migrations.push migrated_at: Time.current, plan: plan
    end
  end
end
