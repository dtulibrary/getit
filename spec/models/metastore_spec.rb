require_relative '../test_helper'

describe Metastore do

  describe "fulltext" do

    params = {
      "url_ver"     => "Z39.88-2004",
      "ctx_ver"     => "Z39.88-2004",
      "ctx_enc"     => "info:ofi/enc:UTF-8",
      "url_ctx_fmt" => "info:ofi/fmt:kev:mtx:ctx",
      "rft_val_fmt" => "info:ofi/fmt:kev:mtx:journal",
      "rft.au"      => "Baillot, Patrick",
      "rft.atitle"  => "Linear+Logic+by+Levels+and+Bounded+Time+Complexity",
      "rft.year"    => "2008",
      "rft.doi"     => "10.1016%2Fj.tcs.2009.09.015",
      "rft_dat"    => "{\"id\":\"1\"}",
      "rft.genre"   => "article",
      "req_id"      => "dtu_staff"
    }

    configuration = {"url" => "http://example.com", "category" => "fulltext", "service_type" => "fulltext"}
    reference = Reference.new(params)

    it "fetches a fulltext url" do

      EM.run_block {
        stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/solr1.txt"))
        metastore = Metastore.new(reference, configuration)
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
        metastore = Metastore.new(reference, configuration)
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
        metastore = Metastore.new(reference, configuration)
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
        metastore = Metastore.new(reference, configuration)
        metastore.callback { |result|        
          result.must_be_empty
        }
        metastore.errback { |error| 
          error.must_match /^Service Metastore failed with status 404*/
        }
      }
    end
  end

  describe "alis" do

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
      "rft_dat"    => "{\"id\":\"244246063\"}",
      "req_id"      => "dtu_staff",
      "svc_dat"     => "fulltext",
      "req_id"      => "dtu_staff"
    }

    configuration = {"url" => "http://example.com", "alis_url" => "http://example.com?id=", "category" => "alis", "service_type" => "fulltext"}
    reference = Reference.new(params)

    it "fetches an alis url" do

      EM.run_block {
        stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/solr4.txt"))
        metastore = Metastore.new(reference, configuration)
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

  describe "holdings" do

    params = {
      "url_ver"     => "Z39.88-2004",
      "url_ctx_fmt" => "info:ofi/fmt:kev:mtx:ctx",
      "ctx_ver"     => "Z39.88-2004",
      "ctx_enc"     => "info:ofi/enc:UTF-8",
      "rft.genre"   => "journal",
      "rft.jtitle"  => "Nature.",
      "rft.issn"    => "14764687",
      "rft_val_fmt" => "info:ofi/fmt:kev:mtx:journal",
      "rft_dat"    => "{\"id\":\"189829043\"}",
      "req_id"      => "dtu_staff",
      "svc_dat"     => "holdings"
    }

    configuration = {"url" => "http://example.com", "category" => "holdings", "service_type" => "fulltext",
      "order_article_url" => "http://example.com"}
    reference = Reference.new(params)

    it "fetches the holdings" do
      EM.run_block {
        stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/solr5.txt"))
        metastore = Metastore.new(reference, configuration)
        metastore.callback { |result|        
          result.first.holdings_list.length.must_equal 3          
          result.first.service_type.must_equal "fulltext"
        }
        metastore.errback { |error| 
          flunk error
        }
      }      
    end
  end
end