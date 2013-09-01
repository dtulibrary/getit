
require_relative 'service'

# Lookup local holding in metastore index and sets scan option to be either dtic
# or rp (reprints desk) based on whether item is included in holdings or not
# TODO limit to articles
class Scan
  include Service

  def initialize(reference, service_settings, cache_settings = {})    
    if service_settings["scan"]["enable_dtic"]
      super(reference, service_settings, cache_settings)
    else
      @configuration = service_settings[self.class.to_s.downcase]
      self.succeed([rd_response(reference)])
    end
  end    

  def parse_response
    service_response = rd_response(@reference)

    article_year = @reference.context_object.referent.metadata["date"].to_i
    article_volume = @reference.context_object.referent.metadata["volume"].to_i
    article_issue = @reference.context_object.referent.metadata["issue"].to_i

    response = JSON.parse(@response[:body])["response"]
    if response["numFound"] > 0
      response["docs"].each do |doc|
        
        if doc.has_key?("holdings_ssf")
          has_local = false
          
          doc["holdings_ssf"].each do |holdings_json|
            holdings = JSON.parse(holdings_json)
          
            if holdings["type"] == "printed"
            
              if article_year != 0 && holdings["fromyear"].to_i <= article_year && holdings["toyear"].to_i >= article_year
                has_local = true
                           
                if
                  # article in volume/issue before holding
                  (article_year == holdings["fromyear"].to_i && 
                  (article_volume < holdings["fromvolume"].to_i ||
                   article_issue < holdings["fromissue"].to_i)) || 
                  # article in volume/issue after holding
                  (article_year == holdings["toyear"].to_i &&
                  (article_volume > holdings["tovolume"].to_i || 
                   article_issue > holdings["toissue"].to_i))
                  has_local = false
                end
              end 
            end            
          end
          # TODO set dtic scan specific texts if local
          service_response.subtype = "dtic_scan" if has_local
        end
      end
    end
    [service_response]
  end  

  def rd_response(reference)
    response = FulltextServiceResponse.new
    response.service_type = "fulltext"
    response.source = "scan"
    response.source_priority = @configuration["priority"]
    response.subtype = "rd_scan"    

    if reference.doctype == 'article'
      lookup_text = "fulltext.article.#{response.subtype}.%s.#{reference.user_type}"

      response.short_name = I18n.t lookup_text % "short_name"
      response.type = I18n.t lookup_text % "type"
      response.short_explanation = I18n.t lookup_text % "short_explanation"
      response.lead_text = I18n.t lookup_text % "lead_text"
      response.explanation = I18n.t lookup_text % "explanation"
      response.button_text = I18n.t lookup_text % "button_text"
      response.tool_tip = I18n.t lookup_text % "tool_tip"
      response.icon = I18n.t lookup_text % "icon"
    end

    response
  end

  def get_query    
    #TODO only make request if we have something meaningful to query with   
    query = ""
    query = "issn_ss:#{@reference.context_object.referent.metadata['issn']}" if !@reference.context_object.referent.metadata['issn'].nil?
    query ||= "isbn_ss:#{@reference.context_object.referent.metadata['isbn']}" if !@reference.context_object.referent.metadata['isbn'].nil?
    query ||= "journal_title_ts:#{@reference.context_object.referent.metadata['jtitle']}" if !@reference.context_object.referent.metadata['jtitle'].nil?
    {"q" => query, "fq" => "format:journal",  "fl" => "holdings_ssf", "wt" => "json"}
  end
end