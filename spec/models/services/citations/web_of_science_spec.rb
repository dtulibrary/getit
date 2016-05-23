require_relative '../../../test_helper'

describe Citations::WebOfScience do
  describe "parse_response" do
    it "parses a response (WITH a citation count and WITH a URL) and returns a hash with 'count' and 'url'" do
      api_response = File.read("spec/fixtures/web_of_science_citation_response.xml")

      ids = { "doi" => '10.1038/nature04924' }
      web_of_science = Citations::WebOfScience.new(ids)
      parsed_response = web_of_science.parse_response(api_response)
      parsed_response[:count].must_equal("116")
      parsed_response[:url].must_equal("http://gateway.webofknowledge.com/gateway/Gateway.cgi?GWVersion=2&SrcApp=PARTNER_APP&SrcAuth=LinksAMR&KeyUT=WOS:000238979700043&DestLinkType=CitingArticles&DestApp=ALL_WOS&UsrCustomerID=e81501f5699c9cebd224e42e1b7f3afa")
    end

    it "parses a response (WITHOUT a citation count + WITHOUT a URL) and returns a hash with 'count' = 0 and no 'url'" do
      api_response = File.read("spec/fixtures/web_of_science_citation_response__without_count__without_url.xml")

      ids = { "doi" => '10.1002/hec.3167' }
      web_of_science = Citations::WebOfScience.new(ids)
      parsed_response = web_of_science.parse_response(api_response)
      parsed_response[:count].must_equal("0")
      parsed_response[:url].must_equal(nil)
    end

    it "parses a response with no results and returns an empty hash" do
      api_response = File.read("spec/fixtures/web_of_science_citation_response__no_result_found.xml")

      ids = { "doi" => '10.1002/hec.3167' }
      web_of_science = Citations::WebOfScience.new(ids)
      parsed_response = web_of_science.parse_response(api_response)
      parsed_response[:count].must_equal(nil)
      parsed_response[:url].must_equal(nil)
    end
  end

  describe "request_body" do
    it "returns an XML request" do
      ids = { "doi" => '10.1038/nature04924' }
      web_of_science = Citations::WebOfScience.new(ids)

      request = web_of_science.request_body

      request.must_include('<map><map name="10.1038/nature04924"><val name="doi">10.1038/nature04924</val></map></map>')
    end

    it "doesn't blow up when doi parameter is null" do
      ids = { }
      web_of_science = Citations::WebOfScience.new(ids)

      request = web_of_science.request_body
    end
  end

  describe "query" do
    it "queries" do
      api_response = File.read("spec/fixtures/web_of_science_citation_response.xml")

      stub_request(:post, "https://ws.isiknowledge.com/cps/xrpc").
        with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/xml', 'Host'=>'ws.isiknowledge.com', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => api_response, :headers => {})

      ids = { "doi" => '10.1038/nature04924' }
      web_of_science = Citations::WebOfScience.new(ids)
      response = web_of_science.query
      response[:count].must_equal("116")
    end
  end
end
