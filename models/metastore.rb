
require 'json'
require_relative 'service'

class Metastore
  include Service

  def initialize(reference, configuration, cache_settings = {})    
    @category = configuration['category']

    if skip?(reference)
      self.succeed([])
    else
      super(reference, configuration, cache_settings)
    end
  end

  def parse_response    
    metastore_response = JSON.parse(@response[:body])["response"]
    count = metastore_response["numFound"]

    service_responses = []
    key = metastore_key

    if count > 0 && metastore_response["docs"].first.has_key?(key)

      case @category
      when "fulltext"        
        
        metastore_response["docs"].first[key].each do |f|          
          service_responses << metastore_fulltext_response(JSON.parse(f))
        end

      when "alis"
        response = metastore_service_response
        alis_key = metastore_response["docs"].first[key].first

        response.url = "#{@configuration['alis_url']}#{alis_key}"
        response.subtype = "catalog"
        response.set_translations(@reference.doctype, response.subtype, @reference.user_type)
        
        service_responses << response      

      when "holdings"                
        response = metastore_service_response
        
        metastore_response["docs"].first[key].each do |holdings_item|
          parsed_item = JSON.parse(holdings_item)
          parsed_item.delete("type")
          response.holdings_list << parsed_item
        end
        
        issn = @reference.context_object.referent.metadata["issn"]
        response.url = "#{@configuration['order_url']}"
        response.subtype = "print"
        
        response.set_translations(@reference.doctype, response.subtype, @reference.user_type)
        service_responses << response      
      end
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

  def self.issn_list
    ["13555855","10650741","14777274","01604953","13527606","14777282","09653562","20407149","14601060","03090566","03090590","17542413","02635577","02641615",
     "0951354X","13552554","09526862","1754243X","01437720","01443577","0265671X","09590552","0144333X","14676370","08858624","07363761","01443585","09578234",
     "17410398","13673270","02621711","1741038X","09534814","1463578X","17575818","13665626","09696474","01435124","20408269","02686902","03074358","09604529",
     "1065075X","00483486","1363951X","02637472","02580543","13527592"]
  end  

  def skip?(reference)
    # exclude some titles from Emerald with publication year from 2013
    @category == "fulltext" && 
    reference.context_object.referent.metadata["date"].to_i >= 2013 &&
    reference.context_object.referent.identifiers.any? do |identifier|       
      if identifier.match(/urn:issn:(\S*)/)
        self.class.issn_list.include?($1)
      end
    end
  end

  private

  def metastore_fulltext_response(fulltext)

    response = metastore_service_response
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

    response.set_translations(@reference.doctype, response.subtype, @reference.user_type)

    if @reference.doctype == "thesis" 
      response.explanation = I18n.t "fulltext.#{@reference.doctype}.#{response.subtype}.%s.#{@reference.user_type}" % "explanation", filename: fulltext["name"]
    end

    response
  end

  def metastore_service_response
    response = FulltextServiceResponse.new
    response.source = "metastore"
    response.service_type = @configuration["service_type"]      
    response.source_priority = @configuration["priority"]
    response
  end

end  