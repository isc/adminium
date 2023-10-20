class Account < ApplicationRecord
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
  validate :db_url_validation

  attr_encrypted :db_url, key: Rails.application.secrets.encryption_key, algorithm: 'aes-256-cbc',
                          v2_gcm_iv: true, mode: :per_attribute_iv_and_salt


  TIPS = %w(basic_search editing enumerable export_import displayed_record advanced_search serialized relationships time_charts keyboard_shortcuts time_zones).freeze

  def valid_db_url?
    db_url.present?
  end

  def displayed_next_tip
    return unless tips_opt_in
    tips = ['welcome'] + Account::TIPS
    return unless last_tip_at.nil? || last_tip_at < 1.day.ago
    tip = tips[(tips.index(last_tip_identifier) || -1) + 1]
    update! last_tip_at: Time.current, last_tip_identifier: tip
    tip
  end

  def table_configuration_for table
    table_configurations.find_or_create_by! table: table
  end

  private

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
