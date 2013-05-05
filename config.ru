require 'sinatra/base'
Dir.glob('./{helpers,controllers,models}/*.rb').each { |file| require file }

I18n.load_path += Dir[File.join(File.dirname(__FILE__), 'locales', '*.yml').to_s]

map('/resolve') { run ResolveController } 
map('/') { run ApplicationController }