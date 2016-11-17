
require 'set'

module RulesHelper

  SCAN_SERVICES = ['dtic_scan', 'tib_scan', 'rd_scan']

  ## user rule helpers

  def user_is_dtu
    lambda do |service_response| 
      @reference.dtu?
    end
  end

  def user_is_not_dtu
    lambda do |service_response| 
      !@reference.dtu?
    end    
  end

  ## service rule helpers 

  def service_is_not(*service_names)
    service_is_not_lambda = lambda do |service_names, service_response|       
      !service_names.include?(service_response.source)
    end
    names = *service_names
    service_is_not_lambda.curry[names]
  end

  def service_and_subtype_is_not(subtype, service_names)    
    service_is_not_lambda = lambda do |service_names, subtype, service_response|
      !service_response.subtype.match(subtype) || !service_names.include?(service_response.source)
    end
    service_is_not_lambda.curry[service_names, subtype]    
  end  

  def service_is_not_scan
    service_is_not(SCAN_SERVICES)
  end

  def service_is_scan
    !service_is_not(SCAN_SERVICES)
  end

  ## status rule helpers

  def has_sent_any
    lambda do |service_response| 
      @status.sent.length > 0
    end
  end

  def has_sent_short_name
    lambda do |service_response|
      @status.responses.collect { |response| response.short_name }.include?(service_response.short_name)
    end
  end

  def has_seen_service_with_same_subtype(service_name)
    has_seen_service_with_same_subtype_lambda = lambda do |service_name, service_response|
      # compare with each result from the given service whether it has been seen before
      # only compare beginning of subtype (licence_|openaccess_)
      @status.seen_with_subtype.has_key?(service_name) && @status.seen_with_subtype[service_name].any? {|subtype| subtype.match(service_response.subtype[/[a-z]+_?/]) }
    end
    has_seen_service_with_same_subtype_lambda.curry[service_name]
  end

  # returns true if any of the service names has been sent or is onhold
  def has_seen_services(subtype = nil, service_names)
    has_seen_services_lambda = lambda do |service_names, service_response|
      if subtype.nil?
        service_names.any? {|name| @status.seen_with_subtype.include?(name)}
      else
        service_names.any? do |name|
          @status.seen_with_subtype.include?(name) &&
          @status.seen_with_subtype[name].any? {|st| st.start_with?(subtype)}
        end
      end
    end
    has_seen_services_lambda.curry[service_names]
  end

  def has_seen_scan_services
    has_seen_services(SCAN_SERVICES)
  end

  # returns false if any of the services names has not been processed
  def has_not_seen_services(service_names)
    has_not_processed_services_lambda = lambda do |service_names, service_response|
      !service_names.subset?(Set.new(@status.seen))
    end
    has_not_processed_services_lambda.curry[Set.new(service_names)]
  end

  def has_not_seen_scan_services
    has_not_seen_services(SCAN_SERVICES)
  end

  # Helpers for combining predicates

  def any?(*predicates)
    lambda do |service_response|
      predicates.any? {|p| p.call(service_response)}
    end
  end

  def all?(*predicates)
    lambda do |service_response|
      predicates.all? {|p| p.call(service_response)}
    end
  end

  # Branch between two predicates based on the return value of a third predicate
  def branch(cond_predicate, predicates = {})
    lambda do |service_response|
      if cond_predicate.call(service_response)
        predicates[:true].call(service_response) if predicates[:true]
      else
        predicates[:false].call(service_response) if predicates[:false]
      end
    end
  end

  # Service specific rule helpers implementing more complex behavior

  # Whether or not to skip the DTIC scan service
  def skip_dtic_scan?
    lambda do |service_response|
      if @reference.dtu?
        has_seen_services(%w(metastore sfx)).call(service_response)
      else
        has_seen_services('openaccess', %w(metastore sfx)).call(service_response)
      end
    end
  end

  # What to wait for before sending the DTIC scan reply
  def wait_dtic_scan?
    lambda do |service_response|
      has_not_seen_services(%w(metastore sfx)).call(service_response)
    end
  end

  # Whether or not to skip the RD service
  def skip_rd_scan?
    lambda do |service_response|
      if @reference.dtu?
        has_seen_services(%w(metastore sfx dtic_scan tib_scan)).call(service_response)
      else
        has_seen_services('openaccess', %w(metastore sfx)).call(service_response) ||
        has_seen_services(%w(dtic_scan)).call(service_response)
      end
    end
  end

  # What to wait for before sending the RD scan reply
  def wait_rd_scan?
    lambda do |service_response|
      services = %w(metastore sfx dtic_scan)
      services << 'tib_scan' if @reference.dtu?
      has_not_seen_services(services).call(service_response)
    end
  end

end
