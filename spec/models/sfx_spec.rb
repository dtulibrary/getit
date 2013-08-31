require_relative '../test_helper'

describe Sfx do

  params = {
    "url_ver"     => "Z39.88-2004",
    "ctx_ver"     => "Z39.88-2004",
    "ctx_enc"     => "info:ofi/enc:UTF-8",
    "url_ctx_fmt" => "info:ofi/fmt:kev:mtx:ctx",
    "rft_val_fmt" => "info:ofi/fmt:kev:mtx:journal",
    "rft.au"      => "Baillot%2C+Patrick",
    "rft.atitle"  => "Linear+Logic+by+Levels+and+Bounded+Time+Complexity",
    "rft.date"    => "2008",
    "rft.doi"     => "10.1016%2Fj.tcs.2009.09.015",
    "rft.data"    => "{\"id\":\"1\"}",
    "req_id"      => "dtu_staff"
  }

  configuration = {"sfx" => {"url" => "http://example.com", "service_types" => ['fulltext']}}
  reference = Reference.new(params)

  it "has a fulltext" do

    EM.run_block {
      stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/sfx_fulltext.txt"))
      sfx = Sfx.new(reference, configuration)
      sfx.callback { |result|        
        result.first.url.must_be :==, "http://globalproxy.cvt.dk/login?url=http://link.springer.com/article/10.1145/2441776.2441941"
        result.first.service_type.must_be :==, "fulltext"
        result.size.must_be :==, 1 
      }
      sfx.errback { |error| 
        flunk error
      }
    }
  end

  it "does not have a fulltext" do

    EM.run_block {
      stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/sfx_no_fulltext.txt"))
      sfx = Sfx.new(reference, configuration)
      sfx.callback { |result|
        result.must_be_empty
      }
      sfx.errback { |error| 
        flunk error
      }
    }
  end
end