require_relative 'service'

class MetastoreAlis
  include Service

  def parse_response    
    response = JSON.parse(@response[:body])["response"]
    count = response["numFound"]

    service_responses = []

    if count > 0 && response["docs"].first.has_key?("alis_key_ssf")

      alis_key = response["docs"].first["alis_key_ssf"].first
      
      response = FulltextServiceResponse.new
      response.url = "#{@configuration['alis_url']}#{alis_key}"
      response.service_type = "fulltext"      
      response.source = "metastore"
      response.source_priority = @configuration["priority"]
      response.subtype = "catalog"
            
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

  def get_query              
    {"q" => "{!raw f=cluster_id_ss v=$id}", "id" => "#{@reference.custom_co_data["id"] || nil}", "fl" => "alis_key_ssf", "wt" => "json"}
  end
end