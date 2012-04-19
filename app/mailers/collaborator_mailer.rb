class CollaboratorMailer < ActionMailer::Base
  default :from => 'Adminium <no-reply@adminium.herokuapp.com>'
  
  def notify_collaboration collaborator
    @collaborator = collaborator
    mail :to => collaborator.email, :subject => "Project #{collaborator.account.name} on Adminium"
  end
  
end
