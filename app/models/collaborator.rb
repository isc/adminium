class Collaborator < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :account
  validates :email, presence: true,
                    format: {with: /([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})/i}
  before_create :match_with_existing_user
  after_create :mail_collaborator
  has_and_belongs_to_many :roles
  attr_accessor :domain

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

  def match_with_existing_user
    self.user = User.find_by email: email, provider: kind unless user
  end

  def mail_collaborator
    CollaboratorMailer.notify_collaboration(self, domain).deliver_later if kind == 'google_oauth2'
  end
end
