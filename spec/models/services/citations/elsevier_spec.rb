require_relative '../../../test_helper'

describe Citations::Elsevier do
  elsevier = Citations::Elsevier.new({'api_key' => 'test_key', 'base_url' => 'http://example.com'})
  ids = { doi: '10.1016%2FS0014-5793(01)03313-0', scopus_id: '000350083900013'}

  describe 'url' do
    it 'should return a query url' do
      elsevier.url(ids).must_include '&doi=10.1016%252FS0014-5793%2801%2903313-0'
      elsevier.url(ids).must_include 'http://example.com'
      elsevier.url(ids).must_include 'apiKey=test_key'
      elsevier.url(ids).must_include '&scopus_id=000350083900013'
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
      parsed[:count].must_equal '45'
    end
  end
end