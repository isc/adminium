# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, 'adminium'
set :repo_url, "https://#{ENV['GITHUB_OAUTH_TOKEN']}@github.com/isc/adminium.git"
set :rbenv_ruby, '2.0.0-p481'
set :bundle_flags, "--deployment"
set :bundle_without, 'development test mysql_support'
set :rails_env, 'production'
set :nginx_server_name, 'adminium.doctolib.vgt'
# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
set :deploy_to, '/app/adminium'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, %w{config/database.yml config/application.yml}

# Default value for linked_dirs is []
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      # execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end

namespace :migration do
  task :copy_database do
    on roles(:app), in: :sequence do
      Bundler.with_clean_env do
        url_dump = `heroku pgbackups:url -a eu-adminium`.strip
        # execute :wget, "\"#{url_dump}\" -O /tmp/adminium.dump"
        execute :echo, 'localhost:*:*:doctolib:mypassword > ~/.pgpass'
        execute :chmod, '0600 ~/.pgpass'
        execute :psql, "-c \"SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE datname = 'adminium' AND pid <> pg_backend_pid() \" adminium --user doctolib -h localhost -w"
        execute :pg_restore, "-d adminium --user doctolib -h localhost /tmp/adminium.dump"
      end
    end
  end
end