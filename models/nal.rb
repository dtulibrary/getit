require "addressable/uri"
require_relative 'service'

class Nal
  include Service

  def initialize(reference, configuration, cache_settings = {})    
    
    skip = reference.doctype == 'book' &&
      reference.context_object.referent.metadata['isbn'].nil? && 
      reference.context_object.referent.metadata['issn'].nil? 

    if skip
      # do not check for books without isbn
      # to prevent wrong matches on title
      self.succeed([])
    else
      super(reference, configuration, cache_settings)
    end
  end

  def parse_response    
    response_list = []
    item_list = JSON.parse(@response[:body]).sort {|x, y| x["public_name_ENG"] <=> y["public_name_ENG"]}
    response = NalFulltextServiceResponse.new

    response.source = "nal"
    response.service_type = "fulltext"                
    response.subtype = "nal"
    response.source_priority = @configuration["priority"]

    item_list.each do |item|
      unless item["errorMessage"]
        unless item["id"] == "dtu"          
          response.url_list[item["public_name_ENG"]] = item["providerHTMLOpenUrl"]
        end
      else     
        @logger.info("Link provider #{item['id']} could not resolve link: #{item['errorMessage']}")
      end
    end

    lookup_text = "fulltext.#{@reference.doctype}.#{response.subtype}.%s.#{@reference.user_type}"
    response.short_name = I18n.t lookup_text % "short_name"
    response.type = I18n.t lookup_text % "type"
    response.short_explanation = I18n.t lookup_text % "short_explanation"
    response.lead_text = I18n.t lookup_text % "lead_text"
    response.explanation = I18n.t lookup_text % "explanation"
    response.button_text = I18n.t lookup_text % "button_text", n: response.url_list.length.to_s
    response.tool_tip = I18n.t lookup_text % "tool_tip"

    if response.url_list.length > 0
      response_list << response    
    end

    response_list
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