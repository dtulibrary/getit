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

  get "/price" do
    content_type :json
    user_type = params["user_type"] || nil
    order_type = params["order_type"] || nil
    if(order_type != nil && 
      user_type != nil &&
      settings.respond_to?("prices") && 
      settings.prices.has_key?(order_type) && 
      settings.prices[order_type].has_key?(user_type))
      { amount: settings.prices[order_type][user_type], currency: "dkr"}.to_json
    else
      status 400
    end    
  end

  get "/prices" do
    content_type :json
    prices = settings.respond_to?("prices") ? settings.prices : {} 
    prices.to_json
  end

  not_found do
    title 'Not Found!'
    erb title
  end

  error do
    "Server error - #{env['sinatra.error'].name}"
  end

end