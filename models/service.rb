
require 'em-http'
require 'active_support/json'

module Service
  include EventMachine::Deferrable

  attr_reader :response

  def initialize(context_object, service_settings, dry_run = false)
    # TODO configuration validation
    @configuration = service_settings[self.class.to_s.downcase]
    @context_object = context_object
    @clean_context_object = cleanup_context_object    
    @response = {}
    if !dry_run
      call
    end
  end    

  def call        
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

  def custom_co_data
    data = {}

    if @context_object.referent.metadata.has_key?('data')
      data = JSON.parse(@context_object.referent.metadata['data']) 
    end

    data
  end

  ### Override in class ###

  def parse_response
    ServiceResponse.new
  end    

  def get_query
    {}
  end

  ###

  private

  def cleanup_context_object
    clean_context_object = @context_object
    clean_context_object.requestor.identifiers.each {|id| clean_context_object.requestor.delete_identifier(id)}        
    clean_context_object.serviceType.first.set_private_data('') if clean_context_object.serviceType.length > 0
    clean_context_object
  end

end