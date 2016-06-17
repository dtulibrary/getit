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
          with(:body => "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n<request xmlns=\"http://www.isinet.com/xrpc41\">\n  <fn name=\"LinksAMR.retrieve\">\n    <list>\n      <!-- authentication -->\n      <map><!-- leave this empty to use IP address for authentication --></map>\n      <!-- what to to return -->\n      <map>\n        <list name=\"WOS\">\n          <val>timesCited</val>\n          <val>doi</val>\n          <val>sourceURL</val>\n          <val>citingArticlesURL</val>\n          <val>relatedRecordsURL</val>\n        </list>\n      </map>\n      <!-- query -->\n      <map><map name=\"10.1038/nature04924\"><val name=\"doi\">10.1038/nature04924</val></map></map>\n    </list>\n  </fn>\n</request>",
               :headers => {'Accept'=>'*/*', 'Content-Type'=>'application/xml', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => api_response, :headers => {})

      ids = { "doi" => '10.1038/nature04924' }
      web_of_science = Citations::WebOfScience.new(ids)
      response = web_of_science.query
      response[:count].must_equal("116")
    end
  end
end
