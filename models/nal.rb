require "addressable/uri"
require_relative 'service'

class Nal
  include Service

  def parse_response

    service_responses = []
    item_list = JSON.parse(@response[:body]).sort {|x, y| x["public_name_ENG"] <=> y["public_name_ENG"]}
      
    item_list.each do |item|
      unless item["errorMessage"]
        unless item["id"] == "dtu"
          s = ServiceResponse.new
          s.url = item["providerHTMLOpenUrl"]
          s.source = "nal"
          s.service_type = "fulltext"                
          s.subtype = "nal"
          s.text = item["public_name_ENG"]
          service_responses << s
        end
      else        
        @logger.info("Link provider #{item['id']} could not resolve link: #{item['errorMessage']}")
      end      
    end
    service_responses
  end

  def get_query
    co = @reference.clean_context_object
    co.referrer.set_identifier("info:sid/dtic.dtu.dk")
    # remove timestamp so context object can be used as cache key    
    co_h = co.to_hash
    co_h.delete("ctx_tim")
    uri = Addressable::URI.new
    uri.query_values = co_h
    {"openurl" => uri.query}
  end

end