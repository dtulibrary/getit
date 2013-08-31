require 'sinatra/base'
require 'sinatra/synchrony'
require 'sinatra/config_file'
require 'i18n'

class ApplicationController < Sinatra::Base
  register Sinatra::Synchrony
  register Sinatra::ConfigFile
  helpers ApplicationHelper

  config_file '../config/config.yml.erb'

  configure :production, :staging, :unstable, :development do
    enable :logging
  end

  get "/" do
    #rdoc :README, :layout_engine => :erb, :views => File.expand_path("..", settings.root)
  end

  not_found do
    title 'Not Found!'
    erb title
  end

  error do
    "Server error - #{env['sinatra.error'].name}"
  end

end