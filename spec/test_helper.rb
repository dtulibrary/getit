
ENV['RACK_ENV'] = 'test'

require 'simplecov'
require 'simplecov-html'
require 'simplecov-rcov'

class SimpleCov::Formatter::MergedFormatter
  def format(result)
     SimpleCov::Formatter::HTMLFormatter.new.format(result)
     SimpleCov::Formatter::RcovFormatter.new.format(result)
  end
end
SimpleCov.formatter = SimpleCov::Formatter::MergedFormatter
SimpleCov.start

require 'minitest/autorun'
require 'webmock/minitest'
require 'rack/test'
require 'openurl'

require 'turn/autorun'

Dir.glob('./{helpers,controllers,models}/*.rb').each { |file| require file }

I18n.load_path += Dir[File.join(File.dirname(__FILE__), '../locales', '*.yml').to_s]