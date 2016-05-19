require_relative '../../../test_helper'

describe Citations::Elsevier do
  ids = { doi: '10.1016/j.stem.2011.10.002', scopus_id: '000350083900013'}
  elsevier = Citations::Elsevier.new({'api_key' => 'test_key'}, ids)

  describe 'url' do
    it 'should return a query url' do
      elsevier.url.must_include 'http://api.elsevier.com/content/search/scopus'
      elsevier.url.must_include 'query=DOI%2810.1016%2Fj.stem.2011.10.002%29'
      elsevier.url.must_include 'OR+SCOPUS-ID%28000350083900013%29'
      elsevier.url.must_include 'apiKey=test_key'
      elsevier.url.must_include 'httpAccept=application%2Fjson'
    end
  end

  describe 'search_params' do
    it 'should return a suitable search string' do
      elsevier.search_params[:query].must_include 'DOI(10.1016/j.stem.2011.10.002)'
      elsevier.search_params[:query].must_include 'OR SCOPUS-ID(000350083900013)'
    end
  end

  describe 'query' do
    # elsevier.query(ids).must_be_kind_of Hash
  end

  describe 'parse_response' do
    it 'should parse the response' do
      api_response = File.read('spec/fixtures/elsevier_citation_response.json')
      parsed = elsevier.parse_response(api_response)
      parsed.must_be_kind_of Hash
      parsed[:count].must_equal '136'
      parsed[:url].must_equal 'http://www.scopus.com/inward/record.url?partnerID=HzOxMe3b&scp=82755170946&origin=inward'
    end

    it 'should return an empty hash if there are no results' do
      errored_response = File.read('spec/fixtures/elsevier_citation_error_response.json')
      parsed = elsevier.parse_response(errored_response)
      parsed.must_be_kind_of Hash
      parsed.must_be_empty
    end
  end
end