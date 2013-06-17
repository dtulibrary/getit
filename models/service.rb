require 'em-http'
require 'dalli'
require 'zlib'

module Service
  include EventMachine::Deferrable

  attr_reader :response

  def initialize(reference, service_settings, cache_settings = {})
    # TODO configuration validation
    @configuration = service_settings[self.class.to_s.downcase]
    @logger = Kyandi.logger
    @reference = reference    
    @cache_client = ServiceCache.new(cache_settings, @configuration["cache_timeout"])
    call
  end    

  def call         
    query = get_query
    cache_key = Zlib.crc32(query.to_s)

    @response = @cache_client.get(cache_key)
    if !@response.nil?
      @logger.info "#{self.class} cache hit with #{cache_key}"
      self.succeed(parse_response)      
    else
      @logger.info "#{self.class} cache miss with #{cache_key}"
      @response = {}
      @logger.info "#{self.class} call service with #{get_query}"
      request = EM::HttpRequest.new(@configuration["url"]).get({
        :query => query
      })      
      request.callback {      
        if request.response_header.status == 200        
          @response[:status] = request.response_header.status
          @response[:header] = request.response_header
          @response[:body] = request.response        
          @cache_client.add(cache_key, @response)
          self.succeed(parse_response)          
        else
          self.fail("Service #{self.class} failed with status #{request.response_header.status} for url: #{@configuration['url']}, query: #{get_query}")
        end
      }
      request.errback {
        self.fail("Error making API call for #{self.class}: #{request.error}")
      }
    end
  end

  class ServiceCache
    attr_reader :client

    def initialize(settings, timeout)
      @enabled = false  
      if settings["enabled"]
        @enabled = true 
        options = {:expires_in => timeout, :compress => true}        
        begin
          @client = Dalli::Client.new(settings["hosts"] || 'localhost:11211', options) 
        rescue Dalli::RingError
          @enabled = false
          # TODO log a warning
        end  
      end
    end

    def get(key)      
      @client.get(key) if @enabled   
    rescue Dalli::RingError
      nil
    end

    def add(key, value)
      @client.add(key, value) if @enabled
    rescue Dalli::RingError
      nil
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