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
    current_account.name = heroku_api.app.info(current_account.heroku_id)['name']
  end

  def set_profile
    return if current_account.name.blank?
    attrs = {}
    app_infos = heroku_api.app.info(current_account.name)
    current_account.owner_email = app_infos['owner']['email']
    attrs[:app_infos] = app_infos.to_yaml
    attrs[:addons_infos] = heroku_api.addon.list_by_app(current_account.name).to_yaml
    AppProfile.create attrs.merge(account_id: current_account.id)
  end

  def set_collaborators
    heroku_collaborators = heroku_api.collaborator.list(current_account.name)
    current_account.total_heroku_collaborators = heroku_collaborators.length
  end

  def db_urls config_vars
    db_urls = []
    config_vars.keys.find_all {|key| key.match(/(HEROKU_POSTGRESQL_.*_URL)|(.*DATABASE_URL.*)/)}.each do |key|
      unless db_urls.map {|d| d[:value]}.include?(config_vars[key])
        db_urls << {key: key, value: config_vars[key]}
      end
    end
    db_urls
  end
end
