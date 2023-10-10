class InstallsController < ApplicationController
  skip_before_action :connect_to_db, unless: :valid_db_url?

  def setup_database_connection
  end
end
