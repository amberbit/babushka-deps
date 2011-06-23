dep "rails-create_user" do
  met? {
    grep(/^#{var :login}/, '/etc/passwd')
  }
  meet {
    sudo "useradd -m -s /bin/bash -G rvm #{var :login}"
  }
end

dep "rails-app_dir" do
  met? {
    check_file "/home/#{var :login}/app", :exist?
  }
  meet {
    shell "mkdir -p /home/#{var :login}/app", :as => var(:login)
  }
end

dep "rails-log_dir" do
  met? {
    check_file "/home/#{var :login}/log", :exist?
  }
  meet {
    shell "mkdir -p /home/#{var :login}/log", :as => var(:login)
  }
end

dep "rails-environment" do
  profile = "/home/#{var :login}/.profile"
  met? {
    grep /^export RAILS_ENV=/, profile
  }
  meet {
    append_to_file "export RAILS_ENV=#{var :environment}", profile
  }
end

dep "rails-less_alias" do
  profile = "/home/#{var :login}/.bashrc"
  met? {
    grep /^alias less/, profile
  }
  meet {
    append_to_file "alias less='less -RS'", profile
  }
end

dep "rails-gemset" do
  met? {
    gemsets = `rvm gemset list`
    gemsets =~ /^#{var :app}$/
  }
  meet {
    shell "rvm gemset create #{var :app}", :as => var(:login)
  }
end

dep "rails-nginx" do
  requires 'rails-setup'

  domain = var(:app).gsub('_', '-')
  domain << '.s' unless var(:environment) == 'production'
  domain << '.amberbit.com'

  config_file = "/opt/nginx/conf/sites/#{domain}"

  met? {
    check_file config_file, :exist?
  }

  meet {
    app_config = <<CONFIG
server {
  listen 80;
  server_name #{domain};
  root /home/#{var :login}/app/current/public;           
  access_log /home/#{var :login}/log/access.log;
  error_log /home/#{var :login}/log/error.log;
  passenger_enabled on;
  rails_env #{var :environment};
}
CONFIG
    append_to_file app_config, config_file
  }

  after {
    sudo "service nginx restart"
    puts "Application available at http://#{domain}"
  }
end

dep "rails-setup" do
  define_var :app
  define_var :environment, :choices => %w[staging production]
  set :login, var(:app) + '-' + var(:environment)
end

dep "rails-add" do
  requires "rails-setup", "rails-create_user", 'rails-app_dir', 'user-locale', 
    'user-rvm', 'user-ssh', 'rails-environment', 'rails-gemset', 'rails-log_dir', 'rails-less_alias'
end

dep "rails-postgresql" do
  requires "rails-setup"
  
  met? {
    result = sudo %Q{psql -c "SELECT rolname FROM pg_roles WHERE rolname = '#{var :login}'"}, :as => 'postgres'
    result =~ /1 row/
  }

  meet {
    sudo "createuser -R -D -A -P #{var :login}", :as => 'postgres'
    sudo "createdb -O #{var :login} #{var :login}", :as => 'postgres'
    puts "Database '#{var :login}' created. User: '#{var :login}'"
  }
end
