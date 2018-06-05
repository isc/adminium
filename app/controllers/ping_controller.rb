class PingController < ActionController::Base
  def ping
    revision = File.read(Rails.root.join('REVISION')).strip rescue 'file-not-found'
    render json: { revision: revision }
  end
end
