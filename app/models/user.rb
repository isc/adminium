class User < ApplicationRecord
  has_many :collaborators
  has_many :accounts, through: :collaborators
  has_many :credentials, dependent: :destroy

  validates :webauthn_id, uniqueness: true
  validates :email, uniqueness: true
  
  after_initialize do
    self.webauthn_id ||= WebAuthn.generate_user_id
  end
end
