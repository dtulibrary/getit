require 'json'
require_relative '../test_helper'
include Rack::Test::Methods

def app
  CitationCountController.new
end

api_response = File.read('spec/fixtures/elsevier_citation_response.json')
ids = { doi: '10.1016/j.stem.2011.10.002', scopus_id: '000350083900013'}

describe '/' do
  it 'should return citations count for elsevier' do
    stub_request(:get,
                 'http://api.elsevier.com/content/search/scopus?apiKey=a96e2a9b3bd3df81c305bbf3675d1ace&httpAccept=application/json&query=DOI(10.1016/j.stem.2011.10.002)%20OR%20SCOPUS-ID(000350083900013)'
    ).to_return(body: api_response)
    get "/?#{URI.encode_www_form(ids)}"
    assert_equal 200, last_response.status
    json = JSON.parse(last_response.body)
    json['elsevier'].must_be_kind_of Hash
    json['elsevier']['count'].must_equal '136'
  end

  it 'should return an empty hash on errored requests' do
    stub_request(:get, 'http://api.elsevier.com/content/search/scopus?apiKey=a96e2a9b3bd3df81c305bbf3675d1ace&httpAccept=application/json&query=DOI(10.1016/j.stem.2011.10.002)%20OR%20SCOPUS-ID(000350083900013)')
        .to_return(:status => [500, 'Internal Server Error'])
    get "/?#{URI.encode_www_form(ids)}"
    json = JSON.parse(last_response.body)
    json['elsevier'].must_be_kind_of Hash
    json['elsevier'].must_be_empty
  end

  it 'should return an error message if no valid ids are provided' do
    get '/?x=y'
    assert_equal 400, last_response.status
  end
end