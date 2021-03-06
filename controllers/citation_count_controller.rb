class CitationCountController < ApplicationController

  VALID_KEYS = %w(doi scopus_id pmid)

  # Takes a hash of document identifiers and queries CitationCount services
  # and returns a json blob with values for teh different services
  # e.g. ?doi=10.1016%2FS0014-5793(01)03313-0&scopus_id=000350083900013
  # returns: { "elsevier" : { "count" : "15", "url" : "http://blabla" }, "web_of_science" : { "count" : "5", "url" : "http://blabla" } }
  get '/' do
    headers "Cache-Control" => "no-cache",
            "Access-Control-Allow-Origin" => "*"

    content_type 'application/json'

    if params_valid?
      elsevier = Citations::Elsevier.new(settings.services['citations']['elsevier'], valid_params)
      web_of_science = Citations::WebOfScience.new(valid_params)
      JSON.generate({ elsevier: elsevier.query, web_of_science: web_of_science.query })
    else
      status 400
      JSON.generate({error: "Invalid input: valid keys are #{VALID_KEYS.join(', ')} only"})
    end
  end

  def params_valid?
    valid_param_keys.size > 0
  end

  def valid_param_keys
    VALID_KEYS & params.keys # array intersection
  end

  def valid_params
    params.select { |k,_| VALID_KEYS.include? k }
  end
end
