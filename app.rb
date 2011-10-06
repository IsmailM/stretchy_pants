# encoding: utf-8
require "bundler"
Bundler.setup
require "compass"
require "sinatra/base"
require "sinatra/config_file"
require "warden"
require "haml"
require "rack-flash"
require "bcrypt"
require "mail"
require "active_support"
require "mongo"
require "mongoid"
require "uri"

# Load helpers
require_relative 'helpers/init'

# This file primarly handles top level configuration and gem loading
# along with filters and such   
#
# Overall project structure inspired by spacemonkey here:
# http://stackoverflow.com/questions/5015471/using-sinatra-for-larger-projects-via-multiple-files
#
class MyApp < Sinatra::Base
  register Sinatra::ConfigFile
  helpers Sinatra::FormHelpers

  # Load core configuration file
  config_file 'config/app_config.yml'

  # Configuration
  use Rack::Session::Cookie, :secret  => 't3h_s3cr3t_is_in_th3_sauc3_', :expire_after => 86400
  use Rack::Flash, :accessorize => [:notice, :error, :success]

  configure :development do
    Compass.add_project_configuration(File.join(Sinatra::Application.root, 'config', 'compass.config'))
    # Sendmail Specific Configuration
    Mail.defaults do
      delivery_method :sendmail
    end
  end

  configure :production do
    # Heroku/Sendgrid Specific Configuration
    options = {
      :address        => "smtp.sendgrid.net",
      :port           => 25,
      :domain         => ENV['SENDGRID_DOMAIN'],
      :user_name      => ENV['SENDGRID_USERNAME'],
      :password       => ENV['SENDGRID_PASSWORD'],
      :authentication => 'plain'
    }

    Mail.defaults do
      delivery_method :smtp, options
    end
  end

  helpers do
    include Rack::Utils
    alias_method :h, :escape_html
  end

  before do
    # Build <title> information
    @app_title = settings.app_name
    @page_title = request.path_info.gsub(/\//,' ').strip.humanize

    # If logged in user is admin then set superuser flag
    @superuser = nil
    if env['warden'].user
      if env['warden'].user.admin
        @superuser = true
      end
    end
  end

  # Pass all Users requests to authentication
  before '/users' do
    check_authentication
    check_superuser
  end

  before '/users/*' do
    check_authentication
    check_superuser
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end
require_relative 'models/init'
require_relative 'routes/init'
