require 'sinatra/base'

require 'require_all'
require_all 'helpers', 'models', 'controllers'

I18n.enforce_available_locales = true
I18n.load_path += Dir[File.join(File.dirname(__FILE__), 'config/locales', '*.yml').to_s]

EM.error_handler do |e|
  Kyandi.logger.error "#{ e.class }: #{ e.message }"
  Kyandi.logger.error "#{ e.backtrace.join("\n") }"
end

map('/resolve') { run ResolveController }
map('/') { run ApplicationController }