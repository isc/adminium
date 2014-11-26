class UpdateCollaboratorsKindForOauth2 < ActiveRecord::Migration
  def change
    Collaborator.where(kind: 'google').update_all kind: 'google_oauth2'
  end
end
