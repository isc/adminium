class User < ApplicationRecord
  has_many :collaborators
  has_many :accounts, through: :collaborators
  has_many :enterprise_accounts,
    -> {where(plan: [Account::Plan::ENTERPRISE, Account::Plan::COMPLIMENTARY]).order('name')},
    through: :collaborators, source: :account
  after_create :match_collaborators

  def self.create_with_omniauth auth
    create! do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.name = auth.info.name
      user.email = auth.extra.id_info.email
    end
  end

  private

  def match_collaborators
    Collaborator.where('kind = ? and email ilike ?', provider, email).update_all user_id: id
  end
end
