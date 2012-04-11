class User < ActiveRecord::Base
  
  has_many :collaborators
  has_many :accounts, through: :collaborators
  has_and_belongs_to_many :roles
  
  after_create :match_collaborators
  
  def permissions account
    roles.where(account_id: account.id).inject({}) do |res, role|
      role.permissions.each do |table, rights|
        res[table] ||= {}
        res[table].merge! rights
      end
      res
    end
  end
  
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
