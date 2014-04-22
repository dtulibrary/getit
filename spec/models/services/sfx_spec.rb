# -*- encoding : utf-8 -*-

require_relative '../../test_helper'

describe Sfx do

  describe "article" do

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
      "rft_dat"    => "{\"id\":\"1\"}",
      "req_id"      => "dtu_staff"
    }

    configuration = {"url" => "http://example.com", "service_type" => 'fulltext'}
    reference = Reference.new(params)

    it "has a fulltext" do

      EM.run_block do
        stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/sfx_fulltext.txt"))
        sfx = Sfx.new(reference, configuration)
        sfx.callback do |result|
          result.first.url.must_be :==, "http://globalproxy.cvt.dk/login?url=http://link.springer.com/article/10.1145/2441776.2441941"
          result.first.service_type.must_be :==, "fulltext"
          result.size.must_be :==, 1
        end
        sfx.errback do |error|
          flunk error
        end
      end
    end

    it "does not have a fulltext" do

      EM.run_block do
        stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/sfx_no_fulltext.txt"))
        sfx = Sfx.new(reference, configuration)
        sfx.callback do |result|
          result.must_be_empty
        end
        sfx.errback do |error|
          flunk error
        end
      end
    end
  end

  describe "journal" do

    params = {
      "url_ver"     => "Z39.88-2004",
      "url_ctx_fmt" => "info:ofi/fmt:kev:mtx:ctx",
      "ctx_ver"     => "Z39.88-2004",
      "ctx_enc"     => "info:ofi/enc:UTF-8",
      "rft.genre"   => "journal",
      "rft.jtitle"  => "Nature.",
      "rft.issn"    => "14764687",
      "rft_id"      => "urn:issn:14764687",
      "rft_val_fmt" => "info:ofi/fmt:kev:mtx:journal",
      "rft_dat"     => "{\"id\":\"189829043\"}",
      "req_id"      => "dtu_staff",
      "svc_dat"     => "fulltext"
    }

    configuration = {"url" => "http://example.com", "service_type" => 'fulltext'}
    reference = Reference.new(params)

    it "includes coverage information" do

      EM.run_block do
        stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/sfx_journal.txt"))
        sfx = Sfx.new(reference, configuration)
        sfx.callback do |result|
          result.first.holdings_list.length.must_equal 1
          result.first.holdings_list.first["fromyear"].must_equal "1950"
          result.first.holdings_list.first["fromvolume"].must_equal "165"
          result.first.holdings_list.first["fromissue"].must_equal "4184"
          result.last.holdings_list.length.must_equal 1
          result.last.holdings_list.first["fromyear"].must_equal "1869"
          result.last.holdings_list.first["fromvolume"].must_equal "1"
          result.last.holdings_list.first["fromissue"].must_equal "1"
          result.last.holdings_list.first["toyear"].must_equal "1875"
          result.last.holdings_list.first["tovolume"].must_equal "12"
          result.last.holdings_list.first["toissue"].must_equal "313"
        end
        sfx.errback do |error|
          flunk error
        end
      end
    end

    it "includes coverage information for multiple holdings" do

      EM.run_block do
        stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/sfx_journal_holdings.txt"))
        sfx = Sfx.new(reference, configuration)
        sfx.callback do |result|
          result.first.holdings_list.length.must_equal 2
          result.first.holdings_list.first.length.must_equal 6
          result.first.holdings_list.first["fromyear"].must_equal "1988"
          result.first.holdings_list.first["fromvolume"].must_equal "1"
          result.first.holdings_list.first["fromissue"].must_equal "1"
          result.first.holdings_list.first["toyear"].must_equal "1994"
          result.first.holdings_list.first["tovolume"].must_equal "6"
          result.first.holdings_list.first["toissue"].must_equal "4"
          result.first.holdings_list.last.length.must_equal 6
          result.first.holdings_list.last["fromyear"].must_equal "1995"
          result.first.holdings_list.last["fromvolume"].must_equal "7"
          result.first.holdings_list.last["fromissue"].must_equal "1"
          result.first.holdings_list.last["toyear"].must_equal "2001"
          result.first.holdings_list.last["tovolume"].must_equal "13"
          result.first.holdings_list.last["toissue"].must_equal "4"
        end
        sfx.errback do |error|
          flunk error
        end
      end
    end

    it "includes coverage information for multiple holdings without symetric from-to elements" do
      EM.run_block do
        stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/sfx_journal_holdings2.txt"))
        sfx = Sfx.new(reference, configuration)
        sfx.callback do |result|
          result.first.holdings_list.length.must_equal 2
          result.first.holdings_list.first.length.must_equal 5
          result.first.holdings_list.first["fromyear"].must_equal "1986"
          result.first.holdings_list.first["fromvolume"].must_equal "1"
          result.first.holdings_list.first["fromissue"].must_equal "1"
          result.first.holdings_list.first["toyear"].must_equal "1994"
          result.first.holdings_list.first["tovolume"].must_equal "9"
          result.first.holdings_list.last.length.must_equal 3
          result.first.holdings_list.last["fromyear"].must_equal "1995"
          result.first.holdings_list.last["fromvolume"].must_equal "10"
          result.first.holdings_list.last["fromissue"].must_equal "1"
        end
        sfx.errback do |error|
          flunk error
        end
      end
    end

    it "has embargo" do
      EM.run_block do
        stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/sfx_journal_embargo.txt"))
        sfx = Sfx.new(reference, configuration)
        sfx.callback do |result|
          result.first.holdings_list.length.must_equal 2
          result.first.holdings_list.last["embargo"].first.must_equal "year"
          result.first.holdings_list.last["embargo"].last.must_equal "1"
        end
        sfx.errback do |error|
          flunk error
        end
      end
    end

    it "has embargo (defined in months)" do
      EM.run_block do
        stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/sfx_journal_embargo2.txt"))
        sfx = Sfx.new(reference, configuration)
        sfx.callback do |result|
          result.last.holdings_list.length.must_equal 2
          result.last.holdings_list.last["embargo"].first.must_equal "month"
          result.last.holdings_list.last["embargo"].last.must_equal "6"
        end
        sfx.errback do |error|
          flunk error
        end
      end
    end

  end

  describe "book" do

    params = {
      "url_ver"     => "Z39.88-2004",
      "url_ctx_fmt" => "info:ofi/fmt:kev:mtx:ctx",
      "ctx_ver"     => "Z39.88-2004",
      "ctx_enc"     => "info:ofi/enc:UTF-8",
      "rft.genre"   => "book",
      "rft.btitle"  => "Women entrepreneurs : inspiring stories from emerging economies and developing countries",
      "rft.au"      => "Guillén, Mauro F.",
      "rft.date"    => "2014",
      "rft.isbn"    => "9780203120989",
      "rft_val_fmt" => "info:ofi/fmt:kev:mtx:book",
      "rft_id"      => ["urn:isbn:1136324593", "urn:isbn:9781136324598", "urn:isbn:9780415523479", "urn:isbn:9780415523486", "urn:isbn:9780203120989"],
      "req_id"      => "dtu_staff"
    }

    configuration = {"url" => "http://example.com", "service_type" => 'fulltext'}
    reference = Reference.new(params)

    it "makes a request per identifier until a response is found" do
      # run_block terminates too early
      EM.run do
        stub_request(:get, /#{configuration['url']}.*rft.isbn=1136324593.*/).to_return(File.new("spec/fixtures/sfx_book_1136324593.txt"))
        stub_request(:get, /#{configuration['url']}.*rft.isbn=9780203120989.*/).to_return(File.new("spec/fixtures/sfx_book_9780203120989.txt"))
        sfx = Sfx.new(reference, configuration)
        sfx.callback do |result|
          result.first.url.must_be :==, "http://globalproxy.cvt.dk/login?url=http://proquestcombo.safaribooksonline.com?xmlId=9780415523479"
          result.first.service_type.must_be :==, "fulltext"
          result.size.must_be :==, 1
          EM.stop
        end
        sfx.errback do |error|
          flunk error
          EM.stop
        end
      end
    end

    it "makes a request per identifier and no response is found" do
      # run_block terminates too early
      EM.run do
        stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/sfx_book_1136324593.txt"))
        sfx = Sfx.new(reference, configuration)
        sfx.callback do |result|
          result.must_be_empty
          EM.stop
        end
        sfx.errback do |error|
          flunk error
          EM.stop
        end
      end
    end
  end
end