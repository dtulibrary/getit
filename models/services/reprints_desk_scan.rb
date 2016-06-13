class ReprintsDeskScan
  include Service

  def parse_response(response)
    return [] unless rd_applies?(response)

    service_response = FulltextServiceResponse.new

    service_response.service_type    = 'fulltext'
    service_response.source          = 'rd_scan'
    service_response.source_priority = @configuration['priority']
    service_response.subtype         = 'rd_scan'

    service_response.set_translations(@reference.doctype, service_response.subtype, @reference.user_type)
    [service_response]
  end

  def rd_applies?(response)
    return [] unless @reference.doctype == 'article'

		solr_response = JSON.parse(response[:body])['response']
		return [] unless solr_response['numFound'] > 0

		doc = Document.new(solr_response['docs'].first)
    doc.english?
  end

  def get_query
    query = { 
      "q" => "{!raw f=cluster_id_ss v=$id}", "id" => "#{@reference.custom_co_data["id"] || nil}",
      "fl" => "subformat_s,language_ss",
      "wt" => "json"
    }   
  end

end
