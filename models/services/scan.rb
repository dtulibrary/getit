require 'ostruct'

# Choose between available scan services based on a number of criteria.
class Scan
  include Service

  def parse_response(resp)
    return [] unless @reference.doctype == 'article'

    service_response = FulltextServiceResponse.new

    service_response.service_type    = "fulltext"
    service_response.source          = "scan"
    service_response.source_priority = @configuration["priority"]
    service_response.sub_type        = choose_scan_service(resp)

    service_response.set_translations(@reference.doctype, service_response.subtype, @reference.user_type)
    [service_response]
  end

  def choose_scan_service(resp)
    (year, volume, issue) = extract_year_volume_issue(@reference)
    docs                  = extract_documents(resp)

    case
    when @configuration['enable_dtic'] && documents.any? {|doc| in_dtic_holdings?(year, volume, issue, doc)}
      'dtic_scan'
    else
      'rd_scan'
    end
  end

  def extract_year_volume_issue reference
    ['date', 'volume', 'issue'].map {|e| reference.context_object.referent.metadata[e].to_i}
  end

  def extract_documents(resp)
    JSON.parse(resp[:body])['response']['docs'] || []
  end

  def extract_endpoint(name, holdings)
    result = {}
    ['year', 'volume', 'issue'].select {|e| holdings.has_key?("#{name}#{e}")}
                               .each   {|e| result[e.to_sym] = holdings["#{name}#{e}"].to_i}
    result
  end

  def in_dtic_holdings?(year, volume, issue, holdings_document)
    holdings_document['holdings_ssf'].map    {|json| JSON.parse(json)}
                                     .select {|holdings| holdings['type'] == 'printed'}
                                     .any? do |holdings|
      from    = extract_endpoint('from', holdings)
      to      = extract_endpoint('to', holdings)
      current = HoldingsEndpoint.new(:year => year, :volume => volume, :issue => issue)

      return true if case
                     when from.year && to.year
                       from.before(current) && current.before(to)
                     when from.year
                       from.before(current)
                     when to.year
                       to.before(current)
                     end
    end
  end

  def response_alternative
    service_response = rd_service_response
    service_response.set_translations(@reference.doctype, service_response.subtype, @reference.user_type)
    [service_response]
  end

  def get_query

    query = ""

    query = "issn_ss:#{@reference.context_object.referent.metadata['issn'].gsub('-', '')}" if !@reference.context_object.referent.metadata['issn'].nil?
    query ||= "isbn_ss:#{@reference.context_object.referent.metadata['isbn'].gsub('-', '')}" if !@reference.context_object.referent.metadata['isbn'].nil?
    query ||= "journal_title_ts:#{@reference.context_object.referent.metadata['jtitle']}" if !@reference.context_object.referent.metadata['jtitle'].nil?

    query.empty? ? nil : {"q" => query, "fq" => "format:journal",  "fl" => "holdings_ssf", "wt" => "json"}
  end

  private

  def rd_service_response
    service_response = FulltextServiceResponse.new
    service_response.service_type = "fulltext"
    service_response.source = "scan"
    service_response.source_priority = @configuration["priority"]
    service_response.subtype = "rd_scan"
    service_response
  end
end
