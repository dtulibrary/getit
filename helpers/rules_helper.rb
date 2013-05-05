
require 'set'

module RulesHelper

  def service_is_not(*service_names)
    service_is_not_lambda = lambda do |service_names, service_response, status|       
      !service_names.include?(service_response.source)
    end
    names = *service_names
    service_is_not_lambda.curry[names]
  end

  def service_and_subtype_is_not(subtype, service_names)    
    service_is_not_lambda = lambda do |service_names, subtype, service_response, status|       
      !service_response.subtype.eql?(subtype) || !service_names.include?(service_response.source)
    end
    service_is_not_lambda.curry[service_names, subtype]    
  end

  def has_seen_any
    lambda do |service_response, status| 
      @status.seen.select {|service_name, subtype| subtype != -1 }.length > 0
    end
  end

  def has_sent_service_with_same_subtype(service_name)
    has_sent_service_with_same_subtype_lambda = lambda do |service_name, service_response, status|      
      @status.seen.has_key?(service_name) && service_response.subtype == @status.seen[service_name]
    end
    has_sent_service_with_same_subtype_lambda.curry[service_name]
  end

  # returns true if any of the service names has been sent
  def has_sent_services(subtype = nil, service_names)
    has_sent_services_lambda = lambda do |service_names, service_response, status|            
      result = service_names.select do |name| 
        status.seen.include?(name) && status.seen[name] != -1 &&
        (status.seen[name] == subtype || subtype.nil?)
      end.length > 0
    end
    has_sent_services_lambda.curry[service_names]
  end

  # returns false if any of the services names has not been processed
  def has_not_processed_services(service_names)
    has_not_processed_services_lambda = lambda do |service_names, service_response, status|      
      !service_names.subset?(Set.new(status.seen.keys))      
    end
    has_not_processed_services_lambda.curry[Set.new(service_names)]
  end

end