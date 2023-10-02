module AppInstall
  def detect_app_name
    current_account.name = current_account.fetch_info.try(:[], 'name')
  end
end
