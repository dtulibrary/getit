
ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'webmock/minitest'
require 'rack/test'
require 'openurl'

require 'turn/autorun'

Dir.glob('./{helpers,controllers,models}/*.rb').each { |file| require file }