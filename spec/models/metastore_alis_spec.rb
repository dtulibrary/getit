require_relative '../test_helper'

describe MetastoreAlis do

  params = {
    "url_ver"     => "Z39.88-2004",
    "url_ctx_fmt" => "info:ofi/fmt:kev:mtx:ctx",
    "ctx_ver"     => "Z39.88-2004",
    "ctx_enc"     => "info:ofi/enc:UTF-8",
    "rft.genre"   => "book",
    "rft.btitle"  => "Advanced engineering mathematics",
    "rft.au"      => "Zill, Dennis G.",
    "rft.date"    => "2014",
    "rft.isbn"    => "9781449679774",
    "rft_val_fmt" => "info:ofi/fmt:kev:mtx:book",
    "rft.data"    => "{\"id\":\"244246063\"}",
    "req_id"      => "dtu_staff",
    "svc_dat"     => "fulltext",
    "req_id"      => "dtu_staff"
  }

  configuration = {"url" => "http://example.com", "alis_url" => "http://example.com?id="}
  reference = Reference.new(params)

  it "finds a alis url" do

    EM.run_block {
      stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/solr4.txt"))
      metastore = MetastoreAlis.new(reference, configuration)
      metastore.callback { |result|        
        result.first.url.must_equal("http://example.com?id=000441656")
        result.first.service_type.must_equal("fulltext")     
      }
      metastore.errback { |error| 
        flunk error
      }
    }
  end
end