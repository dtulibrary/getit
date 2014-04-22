
class ResolveController < ApplicationController

  get '/', provides: 'text/event-stream' do

    halt 400, "Parameters missing" if params.empty?

    headers "Cache-Control" => "no-cache",
            "Access-Control-Allow-Origin" => "*"

    reference = Reference.new(CGI::parse(request.query_string))
    service_list_name = reference.service_list_name || settings.service_list_default
    service_list = settings.service_lists[service_list_name][reference.doctype]
    decider = DispatchDecider.new(service_list_name, reference)

    stream(:keepalive) do |out|

      on_hold = []
      concurrency = service_list.length
      EM::Synchrony::Iterator.new(service_list, concurrency).map do |service_name, iter|

        service_conf = settings.services[service_name]

        if klass = get_class(service_conf["type"])

          logger.info "Calling service #{service_name}"
          service = klass.new(reference, service_conf, settings.cache)

          service.callback do |results|

            EM.synchrony do
              m = EM::Synchrony::Thread::Mutex.new
              m.synchronize do
                # send the responses we already know are safe to send rigth away
                # otherwise push to decision to all services has been executed
                results.each do |result|
                  can_send = decider.can_send(result)
                  if can_send == :yes
                    logger.info("Sending result for #{service_name}")
                    out << "data: #{result.to_json}\n\n"
                  elsif can_send == :maybe
                    on_hold << result
                  end
                  decider.status.update(result, can_send)
                end
                decider.status.update(service_name, :no) if results.empty?
              end
            end
            logger.info "Callback for #{service_name} done"
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
      on_hold.sort_by(&:source_priority).each do |result|
        can_send = decider.can_send(result)
        out << "data: #{result.to_json}\n\n" if can_send == :yes
        decider.status.update(result, can_send)
      end

      out << "event: close\n"
      out << "data: none\n\n"
      out.close

      logger.info("Request done")
    end
  end
end