class CollaboratorMailer < ActionMailer::Base
  default from: 'Adminium <no-reply@adminium.io>'

  def notify_collaboration collaborator, domain
    @collaborator, @domain = collaborator, domain
    mail to: collaborator.email, subject: "Project #{collaborator.account.name} on Adminium"
  end
end
