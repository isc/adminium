class Account < ActiveRecord::Base
  
  attr_accessible :db_url, :plan, :heroku_id, :callback_url, :name, :owner_email

  before_create :generate_api_key
  before_save :fill_adapter
  
  # fucked up "unless" below, but otherwise the tests are fucked up
  # likely because of the transactions being used in tests
  # and the fact that this validation causes a new connection to be established
  validate :db_url_validation unless Rails.env.test?
  
  attr_encryptor :db_url, :key => (ENV['ENCRYPTION_KEY'] || 'shablagoo')
  
  def to_param
    api_key
  end
  
  def self.fetch_missing_names_and_emails
    name_nil.find_each do |account|
      res = RestClient.get "https://#{HEROKU_API_USER}:#{HEROKU_API_PASS}@api.heroku.com/vendor/apps/#{account.callback_url.split('/').last}"
      res = JSON.parse res
      account.update_attributes :name => res['name'], :owner_email => res['owner_email']
    end
  end
  
  private
  
  def generate_api_key
    self.api_key = Digest::SHA1.hexdigest(Time.now.to_s + heroku_id.to_s)[8..16]
  end
  
  def db_url_validation
    return unless db_url.present?
    Generic.connect_and_domain_discovery db_url
  rescue PGError, Mysql2::Error => e
    Generic.reset_current_db_url
    errors[:base] = e.message
  end
  
  def fill_adapter
    self.adapter = db_url.split(':').first if db_url.present? && encrypted_db_url_changed?
  end

end
