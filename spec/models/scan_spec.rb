
require_relative '../test_helper'

describe Scan do

  params_no_local = {
    "url_ver" => "Z39.88-2004",
    "url_ctx_fmt" => "info:ofi/fmt:kev:mtx:ctx",
    "ctx_ver" => "Z39.88-2004",
    "ctx_enc" => "info:ofi/enc:UTF-8",
    "rft.genre" => "article",
    "rft.atitle" => "Comparing the use of social networking and traditional media channels for promoting citizen science",
    "rft.au" => "Robson, Christine",
    "rft.jtitle" => "Computer Supported Cooperative Work",
    "rft.spage" => "1463",
    "rft.epage" => "1468",
    "rft.date" => "2013",
    "rft.issn" => "15737551",
    "rft.isbn" => "9781450313315",
    "rft_val_fmt" => "info:ofi/fmt:kev:mtx:journal",
    "rft_id" => "info:doi/10.1145/2441776.2441941",
    "rft_dat" => "{\"id\":\"236740941\"}",
    "req_id" => "anonymous"
  }

  params_local_not_in_range = {
    "url_ver" => "Z39.88-2004",
    "url_ctx_fmt" => "info:ofi/fmt:kev:mtx:ctx",
    "ctx_ver" => "Z39.88-2004",
    "ctx_enc" => "info:ofi/enc:UTF-8",
    "rft.genre" => "article",
    "rft.atitle" => "Interview<br />The 'art' of being Donald Knuth",
    "rft.au" => "Knuth, Donald",
    "rft.jtitle" => "Communications of the ACM",
    "rft.volume" => "51",
    "rft.spage" => "35",
    "rft.epage" => "39",
    "rft.date" => "2008",
    "rft.issn" => "15577317",
    "rft_val_fmt" => "info:ofi/fmt:kev:mtx:journal",
    "rft_id" => "info:doi/10.1145/1364782.1364794",
    "rft_dat" => "{\"id\":\"83279528\"}",
    "req_id" => "anonymous"
  }

  params_local_in_range = {
    "url_ver" => "Z39.88-2004",
    "url_ctx_fmt" => "info:ofi/fmt:kev:mtx:ctx",
    "ctx_ver" => "Z39.88-2004",
    "ctx_enc" => "info:ofi/enc:UTF-8",
    "rft.genre" => "article",
    "rft.atitle" => "In search of information in visual media",
    "rft.au" => "Gupta, Amarnath",
    "rft.jtitle" => "Communications of the ACM",
    "rft.volume" => "40",
    "rft.spage" => "34",
    "rft.epage" => "42",
    "rft.date" => "1997",
    "rft.issn" => "15577317",
    "rft_val_fmt" => "info:ofi/fmt:kev:mtx:journal",
    "rft_id" => "info:doi/10.1145/265563.265570",
    "rft_dat" => "{\"id\":\"13367718\"}",
    "req_id" => "anonymous"
  }
  
  params_local_in_range_year = {    
    "url_ver" => "Z39.88-2004",
    "url_ctx_fmt" => "info:ofi/fmt:kev:mtx:ctx",
    "ctx_ver" => "Z39.88-2004",
    "ctx_enc" => "info:ofi/enc:UTF-8",
    "rft.genre" => "article",
    "rft.atitle" => "Design testing and analyses of the Nanjing TV tower",
    "rft.jtitle" => "Concrete International",
    "rft.volume" => "16",
    "rft.spage" => "11",
    "rft.spage" => "42",
    "rft.epage" => "44",
    "rft.date" => "1994",
    "rft.issn" => "19447388",
    "rft_dat" => "{\"id\":\"1234\"}",
    "req_id" => "anonymous"
  }

  params_sparse_metadata = {    
    "url_ver" => "Z39.88-2004",
    "url_ctx_fmt" => "info:ofi/fmt:kev:mtx:ctx",
    "ctx_ver" => "Z39.88-2004",
    "ctx_enc" => "info:ofi/enc:UTF-8",
    "rft.genre" => "article",
    "rft.atitle" => "Application conditions for interval constraint propagation",
    "rft.au" => "Hyvonen",
    "rft.date" => "1991",
    "rft_val_fmt" => "info:ofi/fmt:kev:mtx:journal",
    "rft_dat" => "{\"id\":\"1234\"}",
    "req_id" => "anonymous"
  }

  describe "holdings in print collection exists for journal" do

    it "chooses RD scan if the article is not in the holdings range" do

      reference = Reference.new(params_local_not_in_range)
      configuration = {"url" => "http://example.com", "enable_dtic" => true}
        
      EM.run_block {
        stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/holdings.txt"))
        scan = Scan.new(reference, configuration)
        scan.callback { |result|
          result.first.subtype.must_equal "rd_scan"
        }
        scan.errback { |error| 
          flunk error
        }
      }
    end

    it "chooses local scan if the article is in the holdings scan" do

      reference = Reference.new(params_local_in_range)
      configuration = {"url" => "http://example.com", "enable_dtic" => true}
        
      EM.run_block {
        stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/holdings.txt"))
        scan = Scan.new(reference, configuration)
        scan.callback { |result|
          result.first.subtype.must_equal "dtic_scan"
        }
        scan.errback { |error| 
          flunk error
        }
      }
    end

    it "chooses local scan if the article is in the holdings scan where holdings only include year" do

      reference = Reference.new(params_local_in_range_year)
      configuration = {"url" => "http://example.com", "enable_dtic" => true}
        
      EM.run_block {
        stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/holdings_only_year.txt"))
        scan = Scan.new(reference, configuration)
        scan.callback { |result|
          result.first.subtype.must_equal "dtic_scan"
        }
        scan.errback { |error| 
          flunk error
        }
      }
    end

    it "does not choose local scan if local scan is disabled" do
      
      reference = Reference.new(params_local_in_range)
      configuration = {"url" => "http://example.com", "enable_dtic" => false}

      EM.run_block {
        stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/holdings.txt"))
        scan = Scan.new(reference, configuration)
        scan.callback { |result|
          result.first.subtype.must_equal "rd_scan"
        }
        scan.errback { |error| 
          flunk error
        }
      }
    end
  end

  describe "holdings in print collection does not exists for journal" do

    it "does not find a local scan option" do
      
      reference = Reference.new(params_no_local)
      configuration = {"url" => "http://example.com", "enable_dtic" => true}

      EM.run_block {
        stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/holdings_no_result.txt"))
        scan = Scan.new(reference, configuration)
        scan.callback { |result|
          result.first.subtype.must_equal "rd_scan"
        }
        scan.errback { |error| 
          flunk error
        }
      }
    end
  end

  it "returns an rd scan option when metadata is too sparse to detect whether a local scan option exists or not" do

    reference = Reference.new(params_sparse_metadata)
    configuration = {"url" => "http://example.com", "enable_dtic" => true}

    EM.run_block {
      scan = Scan.new(reference, configuration)
      scan.callback { |result|
        result.first.subtype.must_equal "rd_scan"
      }
      scan.errback { |error| 
        flunk error
      }
    }
  end

end
