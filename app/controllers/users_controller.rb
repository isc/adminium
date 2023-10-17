class UsersController < ApplicationController
  skip_before_action :require_account

  def show
  end
end