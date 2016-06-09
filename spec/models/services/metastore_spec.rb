require_relative '../../test_helper'

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
      "rft.date"    => "2008",
      "rft.doi"     => "10.1016%2Fj.tcs.2009.09.015",
      "rft_dat"    => "{\"id\":\"1\"}",
      "rft.genre"   => "article",
      "req_id"      => "dtu_staff"
    }

    configuration = {"url" => "http://example.com", "category" => "fulltext", "service_type" => "fulltext", "dtic_url" => "http://example.com/"}

    it "fetches a fulltext url" do

      EM.run_block do
        reference = Reference.new(params)
        stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/solr1.txt"))
        metastore = Metastore.new(reference, configuration)
        metastore.callback do |result|
          result.first.url.must_equal("http://arxiv.org/abs/0801.1253")
          result.first.service_type.must_equal("fulltext")
        end
        metastore.errback do |error|
          flunk error
        end
      end
    end

    it "choses a local fulltext url over an external" do

      EM.run_block do
        reference = Reference.new(params)
        stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/solr6.txt"))
        metastore = Metastore.new(reference, configuration)
        metastore.callback do |result|
          result.first.url.must_equal("#{configuration['dtic_url']}cup?pi=%2Fs0266%2F4674%2F0999%2F0514.pdf&key=140017028")
          result.first.service_type.must_equal("fulltext")
          result.length.must_equal 1
        end
        metastore.errback do |error|
          flunk error
        end
      end
    end

    it "has no fulltext list" do

      EM.run_block do
        reference = Reference.new(params)
        stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/solr2.txt"))
        metastore = Metastore.new(reference, configuration)
        metastore.callback { |result| result.must_be_empty }
        metastore.errback { |error| flunk error }
      end
    end

    it "does not exists" do

      EM.run_block do
        reference = Reference.new(params)
        stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/solr3.txt"))
        metastore = Metastore.new(reference, configuration)
        metastore.callback { |result| result.must_be_empty }
        metastore.errback { |error| flunk error }
      end
    end

    it "points at wrong server" do

      EM.run_block do
        reference = Reference.new(params)
        stub_request(:get, /#{configuration['url']}.*/).to_return(:status => 404)
        metastore = Metastore.new(reference, configuration)
        metastore.callback { |result| result.must_be_empty }
        metastore.errback { |error| error.must_match /^Service Metastore failed with status 404/ }
      end
    end



    describe 'when searching for student theses' do

      describe 'metastore_fulltext_response' do
        before do
          @parsed_fulltext = {"source"=>"sorbit", "name"=>"Bachelorprojekt.pdf", "local"=>true, "type"=>"other", "url"=>"sorbit?pi=%2F35194.681392.pdf&key=466544331"}
          # we reuse a fixture - the Solr response isn't important for our test but the method will fail if it's missing
          stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/solr1.txt"))
        end

        it 'permits access for dtu users' do
          EM.run_block do
            reference = Reference.new(params.merge("req_id" =>"dtu_staff", 'rft.genre' => 'thesis'))
            metastore = Metastore.new(reference, configuration)
            fulltext = metastore.metastore_fulltext_response(@parsed_fulltext)
            fulltext.url.must_include(@parsed_fulltext['url'])
            fulltext.url.wont_match(/.*visit.*/)
          end
        end
        it 'permits access for public users' do
          EM.run_block do
            reference = Reference.new(params.merge("req_id" =>"public", 'rft.genre' => 'thesis'))
            metastore = Metastore.new(reference, configuration)
            fulltext = metastore.metastore_fulltext_response(@parsed_fulltext)
            fulltext.url.must_include(@parsed_fulltext['url'])
            fulltext.url.wont_match(/.*visit.*/)
          end
        end
      end

    end
  end
  describe 'accessible_full_text' do
    it 'is true when type is openaccess' do
      Metastore.accessible_full_text?('type' => 'openaccess').must_equal true
    end
    it 'is false when type is not openaccess' do
      Metastore.accessible_full_text?('type' => 'lock and key').wont_equal true
    end

    it 'is true when source is orbit' do
      Metastore.accessible_full_text?('type' => 'research', 'source' => 'orbit').must_equal true
    end

    it 'is true when source is sorbit and there is a url' do
      accessible = Metastore.accessible_full_text?('source' => 'sorbit', 'url' => 'http://galoshes.com')
      accessible.must_equal true
    end
    it 'is false when source is sorbit and there is no url' do
      accessible = Metastore.accessible_full_text?('source' => 'sorbit', 'url' => '')
      accessible.wont_equal true
    end
    it 'is false when source is sorbit and the url is nil' do
      accessible = Metastore.accessible_full_text?('source' => 'sorbit', 'url' => nil)
      accessible.wont_equal true
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

      EM.run_block do
        stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/solr4.txt"))
        metastore = Metastore.new(reference, configuration)
        metastore.callback do |result|
          result.first.url.must_equal("http://example.com?id=000441656")
          result.first.service_type.must_equal("fulltext")
        end
        metastore.errback { |error| flunk error }
      end
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
      EM.run_block do
        stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/solr5.txt"))
        metastore = Metastore.new(reference, configuration)
        metastore.callback do |result|
          result.first.holdings_list.length.must_equal 3
          result.first.service_type.must_equal "fulltext"
        end
        metastore.errback { |error| flunk error }
      end
    end
  end
end
