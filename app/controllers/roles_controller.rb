class RolesController < ApplicationController
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
      redirect_to edit_account_path(pane: 'roles'), flash: {success: 'Role successfully created'}
    else
      render :new
    end
  end

  def update
    @role = current_account.roles.find params[:id]
    if @role.update role_params
      redirect_to edit_account_path(pane: 'roles'), flash: {success: 'Role successfully updated'}
    else
      render :new
    end
  end

  def destroy
    @role = current_account.roles.find params[:id]
    @role.destroy
    redirect_to edit_account_path(pane: 'roles'), flash: {success: 'Role successfully destroyed'}
  end

  private

  def role_params
    res = params.require(:role).permit(:name, collaborator_ids: [])
    res[:permissions] = params[:role][:permissions].to_unsafe_h
    res
  end
end
