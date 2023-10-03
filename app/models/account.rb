class Account < ApplicationRecord
  before_create :setup_api_key
  before_save :fill_adapter
  has_many :collaborators, dependent: :destroy
  has_many :users, through: :collaborators
  has_many :roles, dependent: :destroy
  has_many :widgets, dependent: :destroy
  has_many :table_widgets, dependent: :destroy
  has_many :time_chart_widgets, dependent: :destroy
  has_many :pie_chart_widgets, dependent: :destroy
  has_many :stat_chart_widgets, dependent: :destroy
  has_many :searches, dependent: :destroy
  has_many :table_configurations, dependent: :destroy

  attribute :db_url
  validates :db_url, format: %r{((mysql2?)|(postgres(ql)?)):\/\/.*}, allow_blank: true
  # fucked up "unless" below, but otherwise the tests are fucked up
  # likely because of the transactions being used in tests
  # and the fact that this validation causes a new connection to be established
  validate :db_url_validation unless Rails.env.test?

  attr_encrypted :db_url, key: Rails.application.secrets.encryption_key, algorithm: 'aes-256-cbc',
                          v2_gcm_iv: true, mode: :per_attribute_iv_and_salt

  scope :deleted, -> {where plan: Plan::DELETED}
  scope :not_deleted, -> {where.not plan: Plan::DELETED}

  TIPS = %w(basic_search editing enumerable export_import displayed_record advanced_search serialized relationships time_charts keyboard_shortcuts time_zones).freeze

  class Plan
    PET_PROJECT = 'petproject'.freeze
    STARTUP = 'startup'.freeze
    ENTERPRISE = 'enterprise'.freeze
    COMPLIMENTARY = 'complimentary'.freeze
    DELETED = 'deleted'.freeze
  end

  def to_param
    api_key
  end

  def valid_db_url?
    db_url.present?
  end

  def flag_as_deleted!
    update! db_url: nil, api_key: nil, plan: Plan::DELETED, deleted_at: Time.current
  end

  def displayed_next_tip
    return unless tips_opt_in
    tips = ['welcome'] + Account::TIPS
    return unless last_tip_at.nil? || last_tip_at < 1.day.ago
    tip = tips[(tips.index(last_tip_identifier) || -1) + 1]
    update! last_tip_at: Time.current, last_tip_identifier: tip
    tip
  end

  def reactivate attributes
    update attributes.merge(deleted_at: nil, api_key: generate_api_key)
  end

  def table_configuration_for table
    table_configurations.find_or_create_by! table: table
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
    errors.add :base, e.message
  end

  def fill_adapter
    self.adapter = db_url.split(':').first if db_url? && encrypted_db_url_changed?
  end
end
