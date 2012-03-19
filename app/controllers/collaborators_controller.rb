class CollaboratorsController < ApplicationController
  
  skip_before_filter :connect_to_db
  respond_to :html, :json
  
  def create
    collaborator = current_account.collaborators.create params[:collaborator]
    respond_with collaborator, location: edit_account_url
  end
  
  def destroy
    current_account.collaborators.destroy params[:id]
    render nothing: true
  end
  
end
