class InstallsController < ApplicationController
  skip_before_action :connect_to_db, unless: :valid_db_url?

  def setup_database_connection
    @db_urls = session[:db_urls] if session[:db_urls]
  end
end
