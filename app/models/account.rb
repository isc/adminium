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
  has_many :searches

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
      res = account.fetch_info
      next unless res
      account.update owner_email: res['owner_email']
      account.update name: res['name'] unless account.name?
    end
  end

  def fetch_info
    auth = [HEROKU_MANIFEST['id'], HEROKU_MANIFEST['api']['password']].join(':')
    res = RestClient.get "https://#{auth}@api.heroku.com/vendor/apps/#{callback_url.split('/').last.strip}"
    JSON.parse res
  rescue RestClient::ResourceNotFound
    {}
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
