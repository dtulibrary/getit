require 'ostruct'

# Choose between available scan services based on a number of criteria.
class Scan
  include Service

  def parse_response(response)
    return [] unless @reference.doctype == 'article'

    service_response = FulltextServiceResponse.new

    service_response.service_type    = "fulltext"
    service_response.source          = "scan"
    service_response.source_priority = @configuration["priority"]
    service_response.subtype         = choose_scan_service(response)

    service_response.set_translations(@reference.doctype, service_response.subtype, @reference.user_type)
    [service_response]
  end

  def response_alternative
    service_response = rd_service_response
    service_response.set_translations(@reference.doctype, service_response.subtype, @reference.user_type)
    [service_response]
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

  def choose_scan_service(response)
    (year, volume, issue) = extract_year_volume_issue(@reference)
    holdings_documents    = extract_holdings_documents(response)
    current               = HoldingsPoint.new('year' => year, 'volume' => volume, 'issue' => issue)

    case
    when @configuration['enable_dtic'] && holdings_documents.any? {|doc| doc.printed_holdings.any? {|interval| interval.include?(current)}}
      'dtic_scan'
    when @configuration['enable_tib'] && tib_applies?(@reference)
      'tib_scan'
    else
      'rd_scan'
    end
  end

  def extract_year_volume_issue(reference)
    ['date', 'volume', 'issue'].reject {|e| reference.context_object.referent.metadata[e].nil?}
                               .map    {|e| reference.context_object.referent.metadata[e].to_i}
  end

  def extract_holdings_documents(resp)
    (JSON.parse(resp[:body])['response']['docs'] || []).map {|doc| HoldingsDocument.new(doc)}
  end

  def tib_applies?(reference)
    # TODO: implement logic on when to use TIB as scan source 
  end

  def rd_service_response
    service_response = FulltextServiceResponse.new
    service_response.service_type = "fulltext"
    service_response.source = "scan"
    service_response.source_priority = @configuration["priority"]
    service_response.subtype = "rd_scan"
    service_response
  end
end
