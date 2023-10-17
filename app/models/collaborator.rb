class Collaborator < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :account
  validates :email, presence: true,
                    format: {with: /([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})/i}
  has_and_belongs_to_many :roles
  before_create :generate_token

  # FIXME: check table existence
  def permissions
    roles.each_with_object({}) do |role, res|
      role.permissions.each do |table, rights|
        res[table] ||= {}
        res[table].merge! rights
      end
      res
    end
  end

  def name
    user&.name || email
  end

  private
  def generate_token
    self.token = SecureRandom.urlsafe_base64(16)
  end
end
