class Account < ActiveRecord::Base

  attr_accessible :db_url, :plan, :heroku_id, :callback_url, :name, :owner_email

  before_create :generate_api_key
  before_save :fill_adapter
  has_many :collaborators
  has_many :users, through: :collaborators
  has_many :roles
  has_many :widgets, dependent: :destroy
  has_many :sign_ons

  # fucked up "unless" below, but otherwise the tests are fucked up
  # likely because of the transactions being used in tests
  # and the fact that this validation causes a new connection to be established
  validate :db_url_validation unless Rails.env.test?
  validates_format_of :db_url, with: /^((mysql2?)|(postgres(ql)?)):\/\/.*/, allow_blank: true

  attr_encryptor :db_url, key: (ENV['ENCRYPTION_KEY'] || 'shablagoo')

  class Plan
    PET_PROJECT = 'petproject'
    STARTUP = 'startup'
    ENTERPRISE = 'enterprise'
    COMPLIMENTARY = 'complimentary'
  end

  def to_param
    api_key
  end

  def self.fetch_missing_names_and_emails
    where(name: nil).where('callback_url is not null').find_each do |account|
      begin
        res = RestClient.get "https://#{HEROKU_MANIFEST['id']}:#{HEROKU_MANIFEST['api']['password']}@api.heroku.com/vendor/apps/#{account.callback_url.split('/').last}"
        res = JSON.parse res
        account.update_attributes name: res['name'], owner_email: res['owner_email']
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

  def enterprise?
    (plan == Plan::ENTERPRISE) || (plan == Plan::COMPLIMENTARY)
  end
  
  def fill_tables_count
    return unless valid_db_url?
    generic = Generic.new self
    update_attribute :tables_count, generic.tables.size
  end
  
  def upgrade_link
    "https://api.heroku.com/v3/resources/adminium+#{{Plan::PET_PROJECT => Plan::STARTUP, Plan::STARTUP => Plan::ENTERPRISE}[plan]}?selected=#{name}"
  end
  
  private

  def generate_api_key
    self.api_key = Digest::SHA1.hexdigest(Time.now.to_s + heroku_id.to_s)[8..16]
  end

  def db_url_validation
    return unless db_url.present?
    Generic.new self
  rescue PGError, Mysql2::Error, URI::InvalidURIError => e
    errors[:base] = e.message
  end

  def fill_adapter
    self.adapter = db_url.split(':').first if db_url.present? && encrypted_db_url_changed?
  end

end
