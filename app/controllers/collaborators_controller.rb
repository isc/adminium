class CollaboratorsController < ApplicationController
  skip_before_action :connect_to_db

  def create
    current_account.collaborators.create! collaborator_params
    redirect_to edit_account_url(pane: 'collaborators'), flash: {success: 'Collaborator added'}
  end

  def new
    user = User.find_by email: params[:email], provider: 'heroku'
    @collaborator = current_account.collaborators.build user: user, is_administrator: true, kind: 'heroku', email: params[:email]
    render action: 'edit'
  end

  def edit
    @collaborator = current_account.collaborators.find params[:id]
  end

  def update
    collaborator = current_account.collaborators.find params[:id]
    collaborator.update collaborator_params
    redirect_to edit_account_path(pane: 'collaborators'), notice: "Changes on #{collaborator.name} saved"
  end

  def destroy
    current_account.collaborators.destroy params[:id]
    render nothing: true
  end

  private

  def collaborator_params
    params.require(:collaborator).permit :kind, :is_administrator, :email, role_ids: []
  end
end
