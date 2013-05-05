
require_relative '../test_helper'

describe Scan do

  params_no_local = {
    "url_ver"     => "Z39.88-2004",
    "ctx_ver"     => "Z39.88-2004",
    "ctx_enc"     => "info%3Aofi%2Fenc%3AUTF-8",
    "url_ctx_fmt" => "info%3Aofi%2Ffmt%3Akev%3Amtx%3Actx",
    "rft_val_fmt" => "info%3Aofi%2Ffmt%3Akev%3Amtx%3Ajournal",
    "rft.au" => "Robson%2C+Christine",
    "rft.atitle" => "Comparing+the+use+of+social+networking+and+traditional+media+channels+for+promoting+citizen+science",
    "rft.jtitle" => "Computer+Supported+Cooperative+Work",
    "rft.issn" => "09259724",
    "rft.issn" => "15737551",
    "rft.year" => "2013",
    "rft.pages" => "1463-1468",
    "rft.doi" => "10.1145%2F2441776.2441941"
  }

  params_local = {
    "url_ver" => "Z39.88-2004",
    "ctx_ver" => "Z39.88-2004",
    "ctx_enc" => "info%3Aofi%2Fenc%3AUTF-8",
    "url_ctx_fmt" => "info%3Aofi%2Ffmt%3Akev%3Amtx%3Actx",
    "rft_val_fmt" => "info%3Aofi%2Ffmt%3Akev%3Amtx%3Ajournal",
    "rft.au" => "Knuth%2C+Donald",
    "rft.atitle" => "Interview%3Cbr+%2F%3EThe+%27art%27+of+being+Donald+Knuth",
    "rft.jtitle" => "Communications+of+the+ACM",
    "rft.issn" => "00010782",
    "rft.issn" => "15577317",
    "rft.year" => "2008",
    "rft.volume" => "51",
    "rft.issue" => "7",
    "rft.pages" => "35-39",
    "rft.doi" => "10.1145%2F1364782.1364794"
  }

  configuration = {"scan" => {"url" => "http://example.com"}}  

  it "finds a local scan option" do

    context_object = OpenURL::ContextObject.new_from_form_vars(params_local)
    
    EM.run_block {
      stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/holdings.txt"))
      scan = Scan.new(context_object, configuration)
      scan.callback { |result|
        result.first.subtype == "dtic_scan"
      }
      scan.errback { |error| 
        flunk error
      }
    }
  end

  it "does not find a local scan option" do
    
    context_object = OpenURL::ContextObject.new_from_form_vars(params_no_local)

    EM.run_block {
      stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/holdings_no_result.txt"))
      scan = Scan.new(context_object, configuration)
      scan.callback { |result|
        result.first.subtype == "rd_scan"
      }
      scan.errback { |error| 
        flunk error
      }
    }
  end
end
