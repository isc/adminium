class CollaboratorMailerPreview < ActionMailer::Preview
  def notify_collaboration
    CollaboratorMailer.notify_collaboration(Collaborator.first, 'adminium.io')
  end
end
