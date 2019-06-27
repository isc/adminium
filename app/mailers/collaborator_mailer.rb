class CollaboratorMailer < ActionMailer::Base
  default from: 'Adminium <no-reply@adminium.io>'

  def notify_collaboration collaborator, domain
    @collaborator, @domain = collaborator, domain
    mail to: collaborator.email, subject: "Project #{collaborator.account.name} on Adminium"
  end

  def welcome_heroku_collaborator emails, account, user
    @account = account
    @user = user
    mail to: emails, subject: "Adminium add-on has been installed on #{account.name}"
  end
end
