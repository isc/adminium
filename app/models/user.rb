class User < ActiveRecord::Base

  has_many :collaborators
  has_many :accounts, through: :collaborators

  after_create :match_collaborators

  def self.create_with_omniauth auth
    create! do |user|
      user.provider = auth['provider']
      user.uid = auth['uid']
      user.name = auth['info']['name']
      user.email = auth['info']['email']
    end
  end

  def match_collaborators
    Collaborator.where(email: email).update_all user_id: id
  end

end
