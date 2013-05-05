
require "em-synchrony"

class TestService 
  include EventMachine::Deferrable

  def initialize(configuration, context_object)

    EM.synchrony do
      EM::Synchrony.sleep(30)

      response = ServiceResponse.new
      response.url = "http://example.com"
      response.type = "test"
      response.source = "test"
      self.succeed([response])
    end
  end
end