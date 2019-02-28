class CollaboratorsController < ApplicationController
  skip_before_action :connect_to_db

  def index
    @heroku_collaborators = []
    @account_collaborators = @account.collaborators.includes(:roles).order(:email)
    if current_user&.heroku_provider?
      @heroku_collaborators = heroku_api.collaborator.list(current_account.name)
      real_heroku_collaborators = @account.collaborators.where(kind: 'heroku').pluck(:email)
      @heroku_collaborators.delete_if do |heroku_collaborator|
        real_heroku_collaborators.include? heroku_collaborator['user']['email']
      end
    end
    @roles = current_account.roles.order(:name).to_a if current_account.enterprise?
  rescue Excon::Errors::Error
    @heroku_collaborators = []
  end

  def create
    current_account.collaborators.create! collaborator_params.merge(domain: request.host)
    redirect_to collaborators_url, flash: {success: 'Collaborator added'}
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
    redirect_to collaborators_url, notice: "Changes on #{collaborator.name} saved"
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
