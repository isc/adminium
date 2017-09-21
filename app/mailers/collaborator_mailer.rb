class CollaboratorMailer < ActionMailer::Base
  include SendGrid
  sendgrid_enable :ganalytics, :opentrack
  default from: 'Adminium <no-reply@adminium.io>'

  def notify_collaboration collaborator, domain
    sendgrid_category 'notify_collaboration'
    @collaborator, @domain = collaborator, domain
    mail to: collaborator.email, subject: "Project #{collaborator.account.name} on Adminium"
  end

  def welcome_heroku_collaborator emails, account, user
    sendgrid_category 'welcome'
    sendgrid_recipients emails
    @account = account
    @user = user
    mail to: emails, subject: "Adminium add-on has been installed on #{account.name}"
  end
end
