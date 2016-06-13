class DticScan
  include Service

  def parse_response(response)
    return [] unless dtic_applies?(response)

    service_response = FulltextServiceResponse.new

    service_response.service_type    = "fulltext"
    service_response.source          = "dtic_scan"
    service_response.source_priority = @configuration["priority"]
    service_response.subtype         = 'dtic_scan'

    service_response.set_translations(@reference.doctype, service_response.subtype, @reference.user_type)
    [service_response]
  end

  def response_alternative
    []
  end

  def get_query
    metadata = @reference.context_object.referent.metadata
    query = []

    query << "issn_ss:#{metadata['issn'].gsub('-', '')}" unless metadata['issn'].nil?
    query << "isbn_ss:#{metadata['isbn'].gsub('-', '')}" unless metadata['isbn'].nil?
    query << "journal_title_ts:#{metadata['jtitle']}"    unless metadata['jtitle'].nil?

    return {"q" => query.join(' AND '), "fq" => "format:journal",  "fl" => "holdings_ssf", "wt" => "json"} unless query.empty?
  end

  private

  def dtic_applies?(response)
    (year, volume, issue) = extract_year_volume_issue(@reference)
    holdings_documents    = extract_holdings_documents(response)
    current               = DticScan::HoldingsPoint.new('year' => year, 'volume' => volume, 'issue' => issue)

    @reference.doctype == 'article' && holdings_documents.any? {|doc| doc.printed_holdings.any? {|interval| interval.include?(current)}}
  end

  def extract_year_volume_issue(reference)
    ['date', 'volume', 'issue'].reject {|e| reference.context_object.referent.metadata[e].nil?}
                               .map    {|e| reference.context_object.referent.metadata[e].to_i}
  end

  def extract_holdings_documents(resp)
    (JSON.parse(resp[:body])['response']['docs'] || []).map {|doc| HoldingsDocument.new(doc)}
  end

end
