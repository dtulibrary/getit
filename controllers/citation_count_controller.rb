class CitationCountController < ApplicationController

  # Takes a hash of document identifiers and queries CitationCount services
  # and returns a json blob with values for teh different services
  # e.g. ?doi=10.1016%2FS0014-5793(01)03313-0&scopus_id=000350083900013
  # returns: { "elsevier" : { "count" : "15", "backlink" : "http://blabla" } }
  get '/' do
    elsevier = Citations::Elsevier.new(settings.services['citations']['elsevier'])
    elsevier.url(doi: '10.1016%2FS0014-5793(01)03313-0', scopus_id: '000350083900013')

  end
end