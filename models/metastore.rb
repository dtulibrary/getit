
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
      
      url = fulltext["url"]
      if fulltext["local"] == true && /http/.match(url).nil? 
        url.prepend(@configuration["dtic_url"])         
      end

      response = ServiceResponse.new
      response.url = url
      response.service_type = "fulltext"      
      response.source = "metastore"
      response.subtype = fulltext["type"] == "openaccess" ? "openaccess" : "license"
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