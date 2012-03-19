class Collaborator < ActiveRecord::Base
  belongs_to :user
  belongs_to :account
  validates_presence_of :account
  validates :email, presence: true, 
                    format: {with: /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i}
  before_create :match_with_existing_user
  
  def match_with_existing_user
    user = User.where(email: email).first
    self.user_id = user.id if user
  end
end
