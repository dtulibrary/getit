require 'uri'
module Citations
  class Elsevier

    BASE_URL = 'http://api.elsevier.com/content/search/scopus'

    def url_params
      { httpAccept: 'application/json', apiKey: api_key }
    end

    def initialize(config, ids)
      @config = config
      @ids = ids
    end

    def api_key
      @config['api_key']
    end

    def query

    end

    def url
      combined_params = url_params.merge(search_params)
      "#{BASE_URL}?#{URI.encode_www_form(combined_params)}"
    end

    # convert { doi: 'xxx', scopus_id: 'yyy' } => { query: 'DOI(XXX) OR SCOPUS-ID(YYY)' }
    def search_params
      params = { doi: nil, scopus_id: nil, pmid: nil }.merge(@ids).reject {|_,v| v.nil? }
      { query: params.collect {|k,v| "#{k.to_s.upcase.sub('_', '-')}(#{v})"}.join(' OR ') }
    end

    def parse_response(response)
      json = JSON.parse(response)
      result_count = json['search-results']['opensearch:totalResults']
      if result_count == '0'
        {}
      else
        entry = json['search-results']['entry'].first
        # there are a number of links, we need the scopus link, see the fixture for an example
        url = entry['link'].select {|h| h['@ref'] == 'scopus'}.first['@href']
        { count: entry['citedby-count'], url: url }
      end
    end
  end
end