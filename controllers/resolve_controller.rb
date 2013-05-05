require 'openurl'
require_relative 'application_controller'
require_relative '../models/dispatch_decider'

class ResolveController < ApplicationController

  get '/', provides: 'text/event-stream' do    

    halt 400, "Parameters missing" if params.empty?  

    headers "Cache-Control" => "no-cache",
            "Access-Control-Allow-Origin" => "*"

    # create context object from parameters
    # note that no validity check on openurl parameters are made 
    context_object = OpenURL::ContextObject.new_from_form_vars(params)
    user_type = get_user_type(context_object)

    service_list_name = context_object.serviceType.first.private_data if context_object.serviceType.length > 0
    service_list_name ||= settings.service_list_default
    service_list = settings.service_lists[service_list_name]
    logger.info "Request for service list #{service_list_name}"

    decider = DispatchDecider.new(service_list_name, user_type)

    stream(:keepalive) do |out|

      on_hold = []
      concurrency = service_list.length
      EM::Synchrony::Iterator.new(service_list, concurrency).map do |service_name, iter|

        service_conf = settings.services[service_name]

        if klass = get_class(service_conf["type"])
        
          logger.info "Calling service #{service_name}"
          service = klass.new(context_object, settings.services)

          service.callback do |results|
            logger.info("Writing result for #{service_name}")
            
            EM.synchrony do
              m = EM::Synchrony::Thread::Mutex.new
              m.synchronize do
                # send the responses we already know are safe to send rigth away
                # otherwise push to decision to all services has been executed
                results.each do |result|                    
                  can_send = decider.can_send(result)
                  if(can_send == :yes)
                    out << write_response(result, user_type, context_object, settings.prices)
                  elsif(can_send == :maybe)
                    on_hold << result 
                  end
                  decider.status.update(result, can_send == :yes)
                end
                decider.status.mark_no_response(service_name) if results.empty?                
              end
            end
            logger.info "callback done"
            iter.return
          end

          service.errback do |error|            
            decider.status.mark_no_response(service_name)
            logger.error "#{error}"
            iter.return
          end
        else
          logger.error "Service #{service_name} does not exist"
          iter.return
        end
      end

      # process results we haven't decided whether to send yet
      on_hold.sort_by(&:priority).each do |result|        
        can_send = decider.can_send(result)        
        out << write_response(result, user_type, context_object, settings.prices) if can_send == :yes
        decider.status.update(result, can_send == :yes)
      end
      
      out << "event: close\n"
      out << "data: none\n\n"
      out.close

      logger.info("Request done")
    end
  end
end