ActiveSupport::Notifications.subscribe 'associations_discovery' do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  Rails.logger.warn "associations_discovery: #{event.duration.round 1}ms"
end
