
require_relative '../test_helper'

describe Metastore do

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

  configuration = {"metastore" => {"url" => "http://example.com"}}
  context_object = OpenURL::ContextObject.new_from_form_vars(params)

  it "finds a fulltext url" do

    EM.run_block {
      stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/solr1.txt"))
      metastore = Metastore.new(context_object, configuration)
      metastore.callback { |result|
        result.first.url.must_equal("http://arxiv.org/abs/0801.1253")
        result.first.service_type.must_equal("fulltext")
      }
      metastore.errback { |error| 
        flunk error
      }
    }
  end

  it "has no fulltext list" do

    EM.run_block {
      stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/solr2.txt"))
      metastore = Metastore.new(context_object, configuration)
      metastore.callback { |result|        
        result.must_be_empty
      }
      metastore.errback { |error| 
        flunk error
      }      
    }
  end

  it "does not exists" do    

    EM.run_block {
      stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/solr3.txt"))
      metastore = Metastore.new(context_object, configuration)
      metastore.callback { |result|        
        result.must_be_empty
      }
      metastore.errback { |error| 
        flunk error
      }      
    }
  end

  it "points at wrong server" do

    EM.run_block {
      stub_request(:get, /#{configuration['url']}.*/).to_return(:status => 404)
      metastore = Metastore.new(context_object, configuration)
      metastore.callback { |result|        
        result.must_be_empty
      }
      metastore.errback { |error| 
        error.must_match /^Service Metastore failed with status 404*/
      }
    }
  end

end

