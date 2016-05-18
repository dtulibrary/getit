require 'uri'
module Citations
  class Elsevier

    def url_params
      {
          httpAccept: 'application/json',
          apiKey: api_key, scopus_id: nil,
          doi: nil, pubmed_id: nil
      }
    end

    def initialize(config)
      @config = config
    end

    def api_key
      @config['api_key']
    end

    def query(ids)

    end

    def url(identifiers)
      params = url_params.merge(identifiers).reject { |_,v| v.nil? }
      "#{@config['base_url']}?#{URI.encode_www_form(params)}"
    end

    def parse_response(response)
      json = JSON.parse(response)
      count = json['abstract-citations-response']['citeColumnTotalXML']['citeCountHeader']['grandTotal']
      { count: count }
    end
  end
end