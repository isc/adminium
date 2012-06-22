# Load the rails application
require File.expand_path('../application', __FILE__)
puts File.read(File.expand_path('../database.yml', __FILE__))
# Initialize the rails application
MtCrap::Application.initialize!
