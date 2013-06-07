require 'em-http'
require 'dalli'
require 'zlib'

module Service
  include EventMachine::Deferrable

  attr_reader :response

  def initialize(reference, service_settings, cache_settings = {})
    # TODO configuration validation
    @configuration = service_settings[self.class.to_s.downcase]
    @reference = reference    
    @cache_enabled = cache_settings["enabled"] || false
    options = {:expires_in => @configuration["cache_timeout"], :compress => true}        
    @cache_client = Dalli::Client.new(cache_settings["hosts"] || 'localhost:11211', options) if @cache_enabled
    call
  end    

  def call         
    query = get_query
    cache_key = Zlib.crc32(query.to_s)

    @response = @cache_client.get(cache_key) if @cache_enabled    

    if(@cache_enabled && !@response.nil?)
      self.succeed(parse_response)      
    else
      @response = {}
      request = EM::HttpRequest.new(@configuration["url"]).get({
        :query => query
      })      
      request.callback {      
        if request.response_header.status == 200        
          @response[:status] = request.response_header.status
          @response[:header] = request.response_header
          @response[:body] = request.response        
          @cache_client.add(cache_key, @response) if @cache_enabled
          self.succeed(parse_response)          
        else
          self.fail("Service #{self.class} failed with status #{request.response_header.status} for url: #{@configuration['url']}, query: #{get_query}")
        end
      }
      request.errback {
        self.fail("Error making API call: #{request.error}")
      }
    end
  end

  # Override methods below in including class 

  def parse_response
    ServiceResponse.new
  end    

  def get_query
    {}
  end
end