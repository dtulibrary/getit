require 'nokogiri'

module Citations
  class WebOfScience
    include Kyandi

    BASE_URL = "https://ws.isiknowledge.com/cps/xrpc"
    XML_REQUEST = '<?xml version="1.0" encoding="UTF-8" ?>
<request xmlns="http://www.isinet.com/xrpc41">
  <fn name="LinksAMR.retrieve">
    <list>
      <!-- authentication -->
      <map><!-- leave this empty to use IP address for authentication --></map>
      <!-- what to to return -->
      <map>
        <list name="WOS">
          <val>timesCited</val>
          <val>doi</val>
          <val>sourceURL</val>
          <val>citingArticlesURL</val>
          <val>relatedRecordsURL</val>
        </list>
      </map>
      <!-- query -->
      <map><map name="NAME_GOES_HERE"><val name="doi">DOI_GOES_HERE</val></map></map>
    </list>
  </fn>
</request>'

    def initialize(ids)
      ids['doi'] = ids['doi'] || ""
      @ids = ids
    end

    def query
      result = {}

      begin
        response = perform_post_request

        result = parse_response(response)
      rescue Exception => e
        Kyandi.logger.error("Web of Science citation count - Request failed (#{BASE_URL}): Exception raised (message: #{e.message}) (backtrace: #{(e.backtrace || []).join("\n")})")
      end

      result
    end

    def perform_post_request
      uri = URI(BASE_URL)

      Kyandi.logger.info("Web of Science citation count - Querying #{BASE_URL} with request: #{request_body}")

      http_web_of_knowledge = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == "https"
        http_web_of_knowledge.use_ssl = true
      end

      response = http_web_of_knowledge.start do |http|
        request = Net::HTTP::Post.new(uri.to_s)
        request.body = request_body
        request.content_type = "application/xml"

        http.request(request)
      end

      if response.code != "200"
        Kyandi.logger.error("Web of Science citation count - HTTP request failed (url: #{BASE_URL}) (code: #{response.code}) (body: #{response.body})")
        raise Exception.new("Web of Science citation count - HTTP request failed (response code != 200)")
      end

      response.body
    end

    def request_body
      XML_REQUEST.gsub(/NAME_GOES_HERE/, doi).gsub(/DOI_GOES_HERE/, doi)
    end

    def doi
      URI.escape(@ids['doi'])
    end

    def parse_response(response)
      result = {}

      begin
        doc = Nokogiri::XML(response)
        doc.remove_namespaces!

        if parse_response_message(doc) != "No Result Found"
          count = xpath(doc, "//val[@name='timesCited']", "0")
          url = xpath(doc, "//val[@name='citingArticlesURL']", nil)

          result = { count: count, url: url }
        end
      rescue Exception => e
        Kyandi.logger.error("Web of Science citation count - Unable to parse response (response: #{response}) (message: #{e.message}) (backtrace: #{(e.backtrace || []).join("\n")})")
      end

      result
    end

    def parse_response_message(doc)
      xpath(doc, "//val[@name='message']", "")
    end

    def xpath(doc, xpath_expr, default_value = "")
      element = doc.xpath(xpath_expr).first
      if element.nil?
        default_value
      else
        element.text
      end
    end
  end
end
