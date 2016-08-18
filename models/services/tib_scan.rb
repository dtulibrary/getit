class TibScan
  include Service

  def parse_response(response)
    return [] unless tib_applies?(response)

    service_response = FulltextServiceResponse.new

    service_response.service_type    = 'fulltext'
    service_response.source          = 'tib_scan'
    service_response.source_priority = @configuration['priority']
    service_response.subtype         = 'tib_scan'

    service_response.set_translations(@reference.doctype, service_response.subtype, @reference.user_type)
    [service_response]
  end

  def tib_applies?(response)
    return false unless @reference.doctype == 'article'

		solr_response = JSON.parse(response[:body])['response']
		return false unless solr_response['numFound'] > 0

		doc = Document.new(solr_response['docs'].first)
    (!doc.undefined_language? && !doc.english?) || doc.conference_paper?
  end

  def get_query
    query = { 
      "q" => "{!raw f=cluster_id_ss v=$id}", "id" => "#{@reference.custom_co_data["id"] || nil}",
      "fl" => "subformat_s,language_ss,isolanguage_ss",
      "wt" => "json"
    }   
  end

end
