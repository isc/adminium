class CollaboratorMailer < ActionMailer::Base
  include SendGrid
  sendgrid_enable :ganalytics, :opentrack
  sendgrid_subscriptiontrack_text replace: '|unsubscribe_link|'
  default from: 'Adminium <no-reply@adminium.io>'

  def notify_collaboration collaborator
    sendgrid_category 'notify_collaboration'
    @collaborator = collaborator
    mail to: collaborator.email, subject: "Project #{collaborator.account.name} on Adminium"
  end

  def welcome_heroku_collaborator emails, account, user
    sendgrid_category 'welcome'
    sendgrid_recipients emails
    @account = account
    @user = user
    mail to: 'jessy.bernal+should_not_be_receive@gmail.com', subject: "Adminium add-on has been installed on #{account.name}"
  end
end
