Airbrake.configure do |c|
  c.project_id = 118_109
  c.project_key = 'de03551fe3ab192c5ba000258d1c2d93'
  c.root_directory = Rails.root
  c.logger = Rails.logger
  c.environment = Rails.env
  c.ignore_environments = %w(test development)
end

# If Airbrake doesn't send any expected exceptions, we suggest to uncomment the
# line below. It might simplify debugging of background Airbrake workers, which
# can silently die.
# Thread.abort_on_exception = ['test', 'development'].include?(Rails.env)
