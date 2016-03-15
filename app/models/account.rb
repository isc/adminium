class Account < ActiveRecord::Base

  attr_accessible :db_url, :plan, :heroku_id, :callback_url, :name, :owner_email,
    :database_time_zone, :application_time_zone, :db_url_setup_method
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

  validates_format_of :db_url, with: /((mysql2?)|(postgres(ql)?)):\/\/.*/, allow_blank: true
  # fucked up "unless" below, but otherwise the tests are fucked up
  # likely because of the transactions being used in tests
  # and the fact that this validation causes a new connection to be established
  validate :db_url_validation unless Rails.env.test?

  attr_encrypted :db_url, key: (ENV['ENCRYPTION_KEY'] || 'shablagoo')
  
  scope :deleted, -> {where plan: Plan::DELETED}
  scope :not_deleted,  -> {where.not plan: Plan::DELETED}
  
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
    where(owner_email: nil).where('callback_url is not null').find_each do |account|
      begin
        res = RestClient.get "https://#{HEROKU_MANIFEST['id']}:#{HEROKU_MANIFEST['api']['password']}@api.heroku.com/vendor/apps/#{account.callback_url.split('/').last}"
        res = JSON.parse res
        account.update_attribute :owner_email, res['owner_email']
        account.update_attribute :name, res['name'] if account.name.blank?
      rescue RestClient::ResourceNotFound
        # not sure what to do with those accounts
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
    self.db_url = nil
    self.api_key = nil
    self.plan = Plan::DELETED
    self.deleted_at = Time.now
    save!
  end

  def displayed_next_tip
    return unless tips_opt_in
    tips = ['welcome'] + Account::TIPS
    tip = nil
    if last_tip_at.nil? || last_tip_at < 1.day.ago
      tip = tips[(tips.index(last_tip_identifier) || -1) + 1]
    end
    if tip
      self.last_tip_at = Time.current
      self.last_tip_identifier = tip
      save!
    end
    tip
  end
  
  def heroku_id_only
    heroku_id.match(/\d+/).to_s
  end

  def reactivate attributes
    update_attributes attributes.merge(deleted_at: nil, api_key: generate_api_key), without_protection: true
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
    self.adapter = db_url.split(':').first if db_url.present? && encrypted_db_url_changed?
  end

  def track_plan_migration
    self.plan_migrations ||= []
    last_plan = nil
    if self.plan_migrations.last
      last_plan = self.plan_migrations.last[:plan]
    end
    if last_plan.nil? || last_plan != self.plan
      self.plan_migrations.push({migrated_at:Time.now, plan: self.plan})
    end
  end

end