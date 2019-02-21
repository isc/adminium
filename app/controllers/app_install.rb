module AppInstall
  def configure_db_url setup_method
    db_urls = db_urls heroku_api.config_var.info(current_account.name)
    if db_urls.one?
      current_account.db_url = db_urls.first[:value]
      current_account.db_url_setup_method = setup_method
      current_account.save!
      true
    else
      session[:db_urls] = db_urls
      false
    end
  end

  def detect_app_name
    current_account.name = current_account.fetch_info.try(:[], 'name')
  end

  def set_owner_email
    return unless current_account.name?
    app_infos = heroku_api.app.info(current_account.name)
    current_account.owner_email = app_infos['owner']['email']
  end

  def db_urls config_vars
    db_urls = []
    config_vars.keys.find_all {|key| key.match(/(HEROKU_POSTGRESQL_.*_URL)|(.*DATABASE_URL.*)/)}.each do |key|
      db_urls << { key: key, value: config_vars[key] } unless db_urls.map {|d| d[:value]}.include?(config_vars[key])
    end
    db_urls
  end
end
