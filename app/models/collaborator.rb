class Collaborator < ActiveRecord::Base
  belongs_to :user
  belongs_to :account
  validates :account, presence: true
  validates :email, presence: true,
                    format: {with: /([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})/i}
  before_create :match_with_existing_user
  after_create :mail_collaborator
  has_and_belongs_to_many :roles

  # FIXME: check table existence
  def permissions
    roles.each_with_object({}) do |res, role|
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
    user = User.find_by email: email, provider: kind
    self.user_id = user.id if user
  end

  def mail_collaborator
    CollaboratorMailer.notify_collaboration(self).deliver if kind == 'google_oauth2'
  end

  def human_roles
    return 'Administrator' if is_administrator
    roles.map(&:name).join(', ') if roles.present?
  end
end
