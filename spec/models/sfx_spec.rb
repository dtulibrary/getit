
require_relative '../test_helper'

describe Sfx do

  params = {
    "url_ver"     => "Z39.88-2004",
    "ctx_ver"     => "Z39.88-2004",
    "ctx_enc"     => "info%3Aofi%2Fenc%3AUTF-8",
    "url_ctx_fmt" => "info%3Aofi%2Ffmt%3Akev%3Amtx%3Actx",
    "rft_val_fmt" => "info%3Aofi%2Ffmt%3Akev%3Amtx%3Ajournal",
    "rft.au"      => "Baillot%2C+Patrick",
    "rft.atitle"  => "Linear+Logic+by+Levels+and+Bounded+Time+Complexity",
    "rft.year"    => "2008",
    "rft.doi"     => "10.1016%2Fj.tcs.2009.09.015",
    "rft.data"    => "{\"id\":\"1\"}"
  }

  configuration = {"sfx" => {"url" => "http://example.com", "service_types" => ['fulltext']}}
  context_object = OpenURL::ContextObject.new_from_form_vars(params)

  it "has a fulltext" do

    EM.run_block {
      stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/sfx_fulltext.txt"))
      sfx = Sfx.new(context_object, configuration)
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
      sfx = Sfx.new(context_object, configuration)
      sfx.callback { |result|
        result.must_be_empty
      }
      sfx.errback { |error| 
        flunk error
      }
    }
  end
end