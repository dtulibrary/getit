require 'em-http'

module Service
  include EventMachine::Deferrable

  attr_reader :response

  def initialize(reference, service_settings)
    # TODO configuration validation
    @configuration = service_settings[self.class.to_s.downcase]
    @reference = reference
    @response = {}
    call
  end    

  def call            
    puts "calling service with #{get_query}"
    request = EM::HttpRequest.new(@configuration["url"]).get({
      :query => get_query
    })
    
    request.callback {      
      if request.response_header.status == 200        
        @response[:status] = request.response_header.status
        @response[:header] = request.response_header
        @response[:body] = request.response        
        self.succeed(parse_response)
      else
        self.fail("Service #{self.class} failed with status #{request.response_header.status} for url: #{@configuration['url']}, query: #{get_query}")
      end
    }

    request.errback {
      self.fail("Error making API call: #{request.error}")
    }
  end

  # Override methods below in including class 

  def parse_response
    ServiceResponse.new
  end    

  def get_query
    {}
  end

end