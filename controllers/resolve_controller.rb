require_relative 'application_controller'
require_relative '../models/dispatch_decider'

class ResolveController < ApplicationController

  get '/', provides: 'text/event-stream' do    

    halt 400, "Parameters missing" if params.empty?  

    headers "Cache-Control" => "no-cache",
            "Access-Control-Allow-Origin" => "*"

    reference = Reference.new(params)    
    service_list_name = reference.service_list_name || settings.service_list_default
    service_list = settings.service_lists[service_list_name]
    decider = DispatchDecider.new(service_list_name, reference)

    stream(:keepalive) do |out|

      on_hold = []
      concurrency = service_list.length
      EM::Synchrony::Iterator.new(service_list, concurrency).map do |service_name, iter|

        service_conf = settings.services[service_name]

        if klass = get_class(service_conf["type"])
        
          logger.info "Calling service #{service_name}"
          service = klass.new(reference, settings.services, settings.cache)

          service.callback do |results|
            logger.info("Writing result for #{service_name}")
            
            EM.synchrony do
              m = EM::Synchrony::Thread::Mutex.new
              m.synchronize do
                # send the responses we already know are safe to send rigth away
                # otherwise push to decision to all services has been executed
                results.each do |result|                    
                  can_send = decider.can_send(result)
                  if can_send == :yes
                    out << write_response(result, reference, settings.prices)
                  elsif can_send == :maybe
                    on_hold << result 
                  end
                  decider.status.update(result.source, can_send, result.subtype)
                end
                decider.status.update(service_name, :no) if results.empty?                
              end
            end
            logger.info "callback done"
            iter.return
          end

          service.errback do |error|            
            decider.status.update(service_name, :no)
            logger.error "#{error}"
            iter.return
          end
        else
          logger.error "Service #{service_name} does not exist"
          iter.return
        end
      end

      # process results we haven't decided whether to send yet
      on_hold.each do |result|        
        can_send = decider.can_send(result)        
        out << write_response(result, reference, settings.prices) if can_send == :yes
        decider.status.update(result.source, can_send, result.subtype)
      end
      
      out << "event: close\n"
      out << "data: none\n\n"
      out.close

      logger.info("Request done")
    end
  end
end