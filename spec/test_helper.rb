
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
#require 'debugger'

require 'turn/autorun'

require 'require_all'
require_rel '../helpers', '../models', '../controllers'

I18n.enforce_available_locales = true
I18n.load_path += Dir[File.join(File.dirname(__FILE__), '../config/locales', '*.yml').to_s]
