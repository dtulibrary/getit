
require_relative 'service'

# Lookup local holding in metastore index and sets scan option to be either dtic
# or rp (reprints desk) based on whether item is included in holdings or not
class Scan
  include Service

  def parse_response

    unless @reference.doctype == "article"
      return []
    end

    service_response = FulltextServiceResponse.new
    service_response.service_type = "fulltext"
    service_response.source = "scan"
    service_response.source_priority = @configuration["priority"]
    service_response.subtype = "rd_scan"

    if @configuration["enable_dtic"]

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
                    # holdings volume or issue is set
                    (holdings["fromvolume"] != nil || holdings["tovolume"] != nil ||
                    holdings["fromissue"] != nil || holdings["toissue"] != nil) &&
                    (# article in volume/issue before holding
                      (article_year == holdings["fromyear"].to_i && 
                      (article_volume < holdings["fromvolume"].to_i ||
                       article_issue < holdings["fromissue"].to_i)) || 
                      # article in volume/issue after holding
                      (article_year == holdings["toyear"].to_i &&
                      (article_volume > holdings["tovolume"].to_i || 
                       article_issue > holdings["toissue"].to_i)))
                    has_local = false                    
                  end
                end 
              end            
            end     
            service_response.subtype = "dtic_scan" if has_local
          end
        end
      end
    end 

    service_response.set_translations(@reference.doctype, service_response.subtype, @reference.user_type)

    [service_response]
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