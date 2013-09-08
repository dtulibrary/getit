
require 'json'
require_relative 'service'

class Metastore
  include Service

  def initialize(reference, configuration, cache_settings = {})    
    @category = configuration['category']
    super(reference, configuration, cache_settings)
  end

  def parse_response
    metastore_response = JSON.parse(@response[:body])["response"]
    count = metastore_response["numFound"]

    service_responses = []
    key = metastore_key

    if count > 0 && metastore_response["docs"].first.has_key?(key)

      response = FulltextServiceResponse.new
      response.source = "metastore"
      response.service_type = @configuration["service_type"]      
      response.source_priority = @configuration["priority"]

      case @category
      when "fulltext"
        fulltext = JSON.parse(metastore_response["docs"].first[key].first)    
        local = fulltext["local"] == true
        
        url = fulltext["url"]
        if local && /http/.match(url).nil? 
          url.prepend(@configuration["dtic_url"])         
        end
        response.url = url

        if fulltext["type"] == "openaccess"
          response.subtype = "openaccess"
        else
          response.subtype = "license"
        end
        if local
          response.subtype << "_local"
        else
         response.subtype << "_remote"
        end

        if response.subtype.start_with?("license") && @reference.user_type == "public"
          response.url = "http://www.dtic.dtu.dk/english/servicemenu/visit/opening#lyngby"
        end

      when "alis"
        alis_key = metastore_response["docs"].first[key].first

        response.url = "#{@configuration['alis_url']}#{alis_key}"
        response.subtype = "catalog"
        response.set_translations(@reference.doctype, response.subtype, @reference.user_type)

      when "holdings"                
        metastore_response["docs"].first[key].each do |holdings_item|
          parsed_item = JSON.parse(holdings_item)
          parsed_item.delete("type")
          response.holdings_list << parsed_item
        end
        issn = @reference.context_object.referent.metadata["issn"]
        response.url = "#{@configuration['order_url']}"
        response.subtype = "print"
      end

      response.set_translations(@reference.doctype, response.subtype, @reference.user_type)

      service_responses << response      
    end

    service_responses
  end    
  
  def get_query    
    {"q" => "{!raw f=cluster_id_ss v=$id}", "id" => "#{@reference.custom_co_data["id"] || nil}", "fl" => "#{metastore_key}", "wt" => "json"}
  end

  def metastore_key     
    return "alis_key_ssf" if @category == "alis"
    return "holdings_ssf" if @category == "holdings"
    "fulltext_list_ssf" # fulltext
  end
end
