require 'em-http'
require 'dalli'
require 'zlib'

module Service
  include EventMachine::Deferrable

  attr_reader :response

  def initialize(reference, configuration, cache_settings = {})
    @logger = Kyandi.logger
    @configuration = configuration
    @reference = reference
    @cache_client = ServiceCache.new(cache_settings, @configuration["cache_timeout"])

    call(get_query)
  end

  # query can either be a string, hash or array of either
  def call(query)

    if query.nil?
      self.succeed(response_alternative)
    else
      queries = []
      queries << query
      queries.flatten!

      query_str = queries.shift

      cache_key = Zlib.crc32(query.to_s)

      response = @cache_client.get(cache_key)

      if response.nil?
        @logger.info "#{self.class} cache miss with #{cache_key}"
        @logger.info "#{self.class} call service with #{query_str}"

        response = {}
        request = EM::HttpRequest.new(@configuration["url"]).get({
          :query => query_str
        })

        request.callback do

          if request.response_header.status == 200
            response[:status] = request.response_header.status
            response[:header] = request.response_header
            response[:body] = request.response
            @cache_client.add(cache_key, response)
            service_responses = parse_response(response)
            # try again since no service responses were found
            # and all queries haven't been tried yet
            if service_responses.empty? && queries.length > 0
              @logger.info("Retry service #{self.class} with new query")
              call(queries)
            else
              self.succeed(service_responses)
            end
          else
            self.fail("Service #{self.class} failed with status #{request.response_header.status} for url: #{@configuration['url']}, query: #{query_str}")
          end
        end

        request.errback do
          self.fail("Error making API call for #{self.class}: #{request.error}")
        end
      else
        @logger.info "#{self.class} cache hit with #{cache_key}"
        self.succeed(parse_response(response))
      end
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

  def parse_response(response)
    ServiceResponse.new
  end

  def response_alternative
    ServiceResponse.new
  end

  # return string, hash or array of either
  def get_query
    {}
  end
end