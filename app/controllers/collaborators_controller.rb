class CollaboratorsController < ApplicationController
  before_action :require_admin
  skip_before_action :connect_to_db

  def index
    @account_collaborators = @account.collaborators.includes(:roles).order(:email)
    @roles = current_account.roles.order(:name).to_a if current_account.enterprise?
  end

  def create
    current_account.collaborators.create! collaborator_params.merge(domain: request.host)
    redirect_to collaborators_url, success: 'Collaborator added'
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
    redirect_to collaborators_url, success: "Changes on #{collaborator.name} saved"
  end

  def destroy
    current_account.collaborators.destroy params[:id]
    redirect_to collaborators_url, success: 'Collaborator removed'
  end

  private

  def collaborator_params
    params.require(:collaborator).permit :kind, :is_administrator, :email, role_ids: []
  end
end
