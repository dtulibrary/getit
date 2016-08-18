require_relative '../../test_helper'

describe TibScan do

  reference_params = {
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

  describe 'when subformat is conference_paper' do
    it 'returns tib_scan' do
      EM.run_block {
        reference = Reference.new(reference_params)
        configuration = {"url" => "http://example.com"}
        stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/tib_correct_subformat.txt"))
        scan = TibScan.new(reference, configuration)
        scan.callback { |result|
          result.first.subtype.must_equal 'tib_scan'
        }
        scan.errback { |error|
          flunk error
        }
      }
    end
  end

  describe 'when subformat is not conference paper' do
    it 'returns tib_scan when language is non-english' do
      EM.run_block {
        reference = Reference.new(reference_params)
        configuration = {"url" => "http://example.com"}
        stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/tib_wrong_subformat_correct_language.txt"))
        scan = TibScan.new(reference, configuration)
        scan.callback { |result|
          result.first.subtype.must_equal 'tib_scan'
        }
        scan.errback { |error|
          flunk error
        }
      }
    end
    
    it 'returns an empty array when language is english' do
      EM.run_block {
        reference = Reference.new(reference_params)
        configuration = {"url" => "http://example.com"}
        stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/tib_wrong_subformat_wrong_language.txt"))
        scan = TibScan.new(reference, configuration)
        scan.callback { |result|
          result.must_equal []
        }
        scan.errback { |error|
          flunk error
        }
      }
    end

    it 'returns an empty array when language is undefined' do
      EM.run_block {
        reference = Reference.new(reference_params)
        configuration = {"url" => "http://example.com"}
        stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/tib_wrong_subformat_undefined_language.txt"))
        scan = TibScan.new(reference, configuration)
        scan.callback { |result|
          result.must_equal []
        }
        scan.errback { |error|
          flunk error
        }
      }
    end
  end
end
