# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
run MtCrap::Application


# worker_processes 1 # assuming four CPU cores
# Rainbows! do
#   use :FiberPool
#   worker_connections 100
# end
