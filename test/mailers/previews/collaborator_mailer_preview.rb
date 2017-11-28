class CollaboratorMailerPreview < ActionMailer::Preview
  def notify_collaboration
    CollaboratorMailer.notify_collaboration(Collaborator.first, 'adminium.io')
  end

  def welcome_heroku_collaborator
    CollaboratorMailer.welcome_heroku_collaborator(%w(jo@comp.com rick@comp.com), Account.first, User.first)
  end
end
