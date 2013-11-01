
ENV['RACK_ENV'] = 'test'

require 'simplecov'
SimpleCov.start

require 'minitest/autorun'
require 'webmock/minitest'
require 'rack/test'
require 'openurl'

require 'turn/autorun'

Dir.glob('./{helpers,controllers,models}/*.rb').each { |file| require file }

I18n.load_path += Dir[File.join(File.dirname(__FILE__), '../locales', '*.yml').to_s]