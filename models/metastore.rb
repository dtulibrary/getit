
require 'json'
require_relative 'service'

class Metastore
  include Service

  def parse_response    
    response = JSON.parse(@response[:body])["response"]
    count = response["numFound"]

    service_responses = []

    if count > 0 && response["docs"].first.has_key?("fulltext_list_ssf")

      fulltext = JSON.parse(response["docs"].first["fulltext_list_ssf"].first)    
      local = fulltext["local"] == true
      
      url = fulltext["url"]
      if local && /http/.match(url).nil? 
        url.prepend(@configuration["dtic_url"])         
      end

      response = FulltextServiceResponse.new
      response.url = url
      response.service_type = "fulltext"      
      response.source = "metastore"
      response.source_priority = @configuration["priority"]

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
            
      lookup_text = "fulltext.#{@reference.doctype}.#{response.subtype}.%s.#{@reference.user_type}"

      response.short_name = I18n.t lookup_text % "short_name"
      response.type = I18n.t lookup_text % "type"
      response.short_explanation = I18n.t lookup_text % "short_explanation"
      response.lead_text = I18n.t lookup_text % "lead_text"
      response.explanation = I18n.t lookup_text % "explanation"
      response.button_text = I18n.t lookup_text % "button_text"
      response.tool_tip = I18n.t lookup_text % "tool_tip"
      response.icon = I18n.t lookup_text % "icon"

      service_responses << response      
    end

    service_responses
  end    

  #TODO option to make fuzzy or not
  def get_query              
    {"q" => "{!raw f=cluster_id_ss v=$id}", "id" => "#{id}", "fl" => "fulltext_list_ssf", "wt" => "json"}
  end

  private

  def id
    @reference.custom_co_data["id"] || nil
  end

end