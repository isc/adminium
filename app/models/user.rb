class User < ActiveRecord::Base

  has_many :collaborators
  has_many :accounts, through: :collaborators
  has_many :enterprise_accounts, through: :collaborators, source: :account,
    conditions: {plan: [Account::Plan::ENTERPRISE, Account::Plan::COMPLIMENTARY]},
    order: 'name'

  after_create :match_collaborators

  def self.create_with_omniauth auth
    create! do |user|
      user.provider = auth['provider']
      user.uid = auth['uid']
      user.name = auth['info']['name']
      user.email = auth['info']['email']
    end
  end
  
  def self.create_with_heroku infos
    create! do |user|
      user.provider = 'heroku'
      user.uid = infos['id']
      user.name = infos['name']
      user.email = infos['email']
    end
  end
  
  def heroku_provider?
    self.provider == 'heroku'
  end

  def match_collaborators
    Collaborator.where('email ilike ?', email).update_all user_id: id
  end

end
