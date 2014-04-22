
require "em-synchrony"

class TestService 
  include EventMachine::Deferrable

  def initialize(reference, service_settings, cache_settings = {})

    EM.synchrony do
      EM::Synchrony.sleep(10)

      response = ServiceResponse.new
      response.url = "http://example.com"
      response.service_type = "test"
      response.source = "test"
      self.succeed([response])
    end
  end
end