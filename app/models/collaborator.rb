class Collaborator < ActiveRecord::Base

  belongs_to :user
  belongs_to :account
  validates_presence_of :account
  validates :email, presence: true,
                    format: {with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i}
  before_create :match_with_existing_user
  after_create :mail_collaborator

  has_and_belongs_to_many :roles

  def permissions
    roles.inject({}) do |res, role|
      role.permissions.each do |table, rights|
        res[table] ||= {}
        res[table].merge! rights
      end
      res
    end
  end

  def name
    user.try(:name) || email
  end

  def match_with_existing_user
    user = User.where(email: email, provider: kind).first
    self.user_id = user.id if user
  end

  def mail_collaborator
    if kind == 'google'
      CollaboratorMailer.notify_collaboration(self).deliver
    end
  end

  def human_roles
    return "administrator" if is_administrator
    roles.map(&:name).join(", ") if roles.present?
  end

end
