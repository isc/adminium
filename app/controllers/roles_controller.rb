class RolesController < ApplicationController
  before_action :require_admin
  skip_before_action :connect_to_db, except: %i(new edit)

  def index
    @roles = current_account.roles.order(:name).to_a if current_account.enterprise?
  end

  def new
    @role = current_account.roles.build permissions: {}
  end

  def edit
    @role = current_account.roles.find params[:id]
    render :new
  end

  def create
    @role = current_account.roles.build role_params
    if @role.save
      log_events
      redirect_to roles_url, success: 'Role successfully created'
    else
      render :new
    end
  end

  def update
    @role = current_account.roles.find params[:id]
    if @role.update role_params
      log_events
      redirect_to roles_url, success: 'Role successfully updated'
    else
      render :new
    end
  end

  def destroy
    @role = current_account.roles.find params[:id]
    @role.destroy!
    log_events
    redirect_to roles_url, success: 'Role successfully destroyed'
  end

  private

    def log_events
      base = { account: current_account.name, username: current_user&.name, role: "#{@role.name} (id:#{@role.id})" }
      return logger.warn base.merge(action: 'destroy-role').to_json if action_name == 'destroy'
      if @role.saved_change_to_permissions?
        logger.warn base.merge(action: 'update-role-permissions',
          permissions: Hashdiff.diff(*@role.saved_changes[:permissions])).to_json
      end
      if role_params[:collaborator_ids].present?
        logger.warn base.merge(action: 'update-role-members', collaborators: role_params[:collaborator_ids])
      end
    end

    def role_params
      params.require(:role).permit(:name, collaborator_ids: [], permissions: {})
    end
end
