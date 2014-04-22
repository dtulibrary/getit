
require 'json'

class Metastore
  include Service

  def initialize(reference, configuration, cache_settings = {})
    @category = configuration['category']

    super(reference, configuration, cache_settings)
  end

  def parse_response(response)
    metastore_response = JSON.parse(response[:body])["response"]
    count = metastore_response["numFound"]

    service_responses = []
    key = metastore_key

    if count > 0 && metastore_response["docs"].first.has_key?(key)

      case @category
      when "fulltext"

        responses = []
        metastore_response["docs"].first[key].each do |f|
          responses << metastore_fulltext_response(JSON.parse(f))
        end

        sr_licensed, sr_openaccess = responses.partition {|sr| sr.subtype.match("license") }
        # sort on subtype - pick local over remote
        service_responses << sr_licensed.sort_by(&:subtype).first unless sr_licensed.empty?
        service_responses << sr_openaccess.first unless sr_openaccess.empty?

      when "alis"
        response = metastore_service_response
        alis_key = metastore_response["docs"].first[key].first

        response.url = "#{@configuration['alis_url']}#{alis_key}"
        response.subtype = "catalog"
        response.set_translations(@reference.doctype, response.subtype, @reference.user_type)

        service_responses << response

      when "holdings"
        response = metastore_service_response

        metastore_response["docs"].first[key].each do |holdings_item|
          parsed_item = JSON.parse(holdings_item)
          parsed_item.delete("type")
          response.holdings_list << parsed_item
        end

        issn = @reference.context_object.referent.metadata["issn"]
        response.url = "#{@configuration['order_url']}"
        response.subtype = "print"

        response.set_translations(@reference.doctype, response.subtype, @reference.user_type)
        service_responses << response
      end
    end

    service_responses
  end

  def get_query

    skip_sources = []
    if @configuration.has_key?("skip_sources")
      skip_sources = @configuration["skip_sources"].map { |s| "NOT source_ss:#{s}" }
    end
    skip_sources << "access_ss:#{@reference.dtu? ? 'dtu' : 'dtupub'}"

    query = {
      "q" => "{!raw f=cluster_id_ss v=$id}", "id" => "#{@reference.custom_co_data["id"] || nil}",
      "fl" => "#{metastore_key}",
      "fq" => skip_sources,
      "wt" => "json"
    }
    Rack::Utils.build_query(query)

  end

  def metastore_key
    return "alis_key_ssf" if @category == "alis"
    return "holdings_ssf" if @category == "holdings"
    "fulltext_list_ssf" # fulltext
  end

  private

  def metastore_fulltext_response(fulltext)

    response = metastore_service_response
    local = fulltext["local"] == true

    url = fulltext["url"]
    if local && /http/.match(url).nil?
      url.prepend(@configuration["dtic_url"])
    end

    response.url = url

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

    response.set_translations(@reference.doctype, response.subtype, @reference.user_type)

    if @reference.doctype == "thesis"
      response.tool_tip = I18n.t "fulltext.#{@reference.doctype}.#{response.subtype}.%s.#{@reference.user_type}" % "tool_tip", filename: fulltext["name"]
    end

    response
  end

  def metastore_service_response
    response = FulltextServiceResponse.new
    response.source = "metastore"
    response.service_type = @configuration["service_type"]
    response.source_priority = @configuration["priority"]
    response
  end

end