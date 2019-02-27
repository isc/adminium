class RolesController < ApplicationController
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
      redirect_to roles_url, flash: {success: 'Role successfully created'}
    else
      render :new
    end
  end

  def update
    @role = current_account.roles.find params[:id]
    if @role.update role_params
      redirect_to roles_url, flash: {success: 'Role successfully updated'}
    else
      render :new
    end
  end

  def destroy
    @role = current_account.roles.find params[:id]
    @role.destroy
    redirect_to roles_url, flash: {success: 'Role successfully destroyed'}
  end

  private

  def role_params
    params.require(:role).permit(:name, collaborator_ids: [], permissions: {})
  end
end
