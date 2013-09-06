require_relative '../test_helper'

describe Nal do

  params = {
    "rft.genre" => "article"
  }

  configuration = {"url" => "http://example.com", "service_types" => ['fulltext']}
  reference = Reference.new(params)

  it "finds Nal fulltext links" do
    EM.run_block {
      stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/nal.txt"))
      nal = Nal.new(reference, configuration)
      nal.callback { |result|                
        result.first.url_list.size.must_be :==, 3
      }
      nal.errback { |error| 
        flunk error
      }
    }
  end

  it "ignore errors in nal responses" do
    EM.run_block {
      stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/nal_with_error.txt"))
      nal = Nal.new(reference, configuration)
      nal.callback { |result|        
        result.first.url_list.size.must_be :==, 1
      }
      nal.errback { |error| 
        flunk error
      }
    }
  end
end