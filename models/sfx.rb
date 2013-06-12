require 'nokogiri'
require_relative 'service'

class Sfx
  include Service

  def initialize(reference, configuration, cache_settings = {})    
    # mapping of service type names between SFX and GetIT
    @sfx_to_getit_types = {"getFullTxt" => "fulltext"}
    
    super(reference, configuration, cache_settings)
  end

  def parse_response

    service_responses = []
    doc = Nokogiri::XML(@response[:body])     

    unless doc.at('/ctx_obj_set')      
      return []
    end

    # multiple context objects can be returned
    sfx_objs = doc.search('/ctx_obj_set/ctx_obj')

    sfx_objs.each do |context_object| 

      context_object.search('./ctx_obj_targets/target').each do |target|

        service_type = target.at("./service_type").inner_text

        if @configuration["service_types"].include?(@sfx_to_getit_types[service_type])

          response = ServiceResponse.new
          response.url = target.at("./target_url").inner_text.chomp("/")
          response.service_type = @sfx_to_getit_types[service_type]
          response.source = "sfx"

          if (target/"./target_public_name").inner_text =~ /open access/i
            response.subtype = "openaccess"
          else
            response.subtype = "license"
          end

          # only include response if it's not a duplicate (i.e. different target names but identical URLs)
          if !duplicate?(response, service_responses)
            service_responses << response
          end
        end
      end
    end
    service_responses
  end

  def get_query    
    co = @reference.clean_context_object
    co.serviceType.push(OpenURL::ContextObjectEntity.new) if co.serviceType.length == 0
    @sfx_to_getit_types.values.each do |service_type|
      co.serviceType.first.set_metadata(service_type, "yes")
    end    
    co_h = co.to_hash.merge({"req.ip" => "127.0.0.1", "sfx.response_type" => "multi_obj_xml"})
    # remove timestamp so it can be used as cache key    
    co_h.delete("ctx_tim")
    if @reference.doctype == "journal"
      co_h["sfx.ignore_date_threshold"] = 1
    end
    co_h
  end

  private

  def duplicate?(response, service_responses)
    service_responses.select { |r| r.url == response.url && r.service_type == response.service_type }.size > 0   
  end

end