require_relative '../../test_helper'

describe Aleph do

  params = {
    "url_ver"=>"Z39.88-2004",
    "url_ctx_fmt"=>"info:ofi/fmt:kev:mtx:ctx",
    "ctx_ver"=>"Z39.88-2004",
    "ctx_enc"=>"info:ofi/enc:UTF-8",
    "rft.genre"=>"book",
    "rft.btitle"=>"Design for manufacturability : How to use concurrent engineering to rapidly develop low-cost, high-quality products for lean production",
    "rft.pub"=>"CRC Press, Taylor & Francis Group",
    "rft.au"=>"Anderson, David M.",
    "rft.date"=>"2014",
    "rft.isbn"=>"9781482204926",
    "rft_val_fmt"=>"info:ofi/fmt:kev:mtx:book",
    "rft_id"=>"urn:isbn:9781482204926",
    "rfr_id"=>"info:sid/findit.dtu.dk",
    "rft_dat"=>"{\"alis_id\":\"123456789\"}",
    "req_id"=>"dtu_staff",
    "svc_dat"=>"loan"
  }

  configuration = { "url" => "http://example.com", "service_type" => "loan", "username" => "123", "password" => "abc", "aleph_url" => "http://example.com/" }

  it "merges locations" do

    EM.run_block do
      reference = Reference.new(params)
      stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/aleph_000489193.txt"))
      aleph = Aleph.new(reference, configuration)
      aleph.callback do |result|
        result.first.locations.size.must_equal 1

        first_status = result.first.locations["DTU Lyngby"].first
        first_status.text.must_equal "Available from 2/6-2014"
        first_status.text_long.must_equal "Available for loan from 2/6-2014"
        first_status.icon.must_equal "icon-minus-circle"
        first_status.callno.must_equal "331.41/.42 Large"
        first_status.url.must_equal "http://example.com/123456789"

        second_status = result.first.locations["DTU Lyngby"].last
        second_status.text.must_equal "Available"
        second_status.text_long.must_equal "Available for loan"
        second_status.icon.must_equal "icon-check"
        second_status.callno.must_equal "331.4 LAR"
        second_status.url.must_equal "http://example.com/123456789"

        result.first.summary.must_equal second_status
      end
      aleph.errback do |error|
        flunk error
      end
    end
  end

  it "includes a single location" do

    EM.run_block do
      reference = Reference.new(params)
      stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/aleph_000590431.txt"))
      aleph = Aleph.new(reference, configuration)
      aleph.callback do |result|
        result.first.locations.size.must_equal 1
        status = result.first.locations["DTU Lyngby"].first
        status.text.must_equal "Available from 2/6-2014"
        status.text_long.must_equal "Available for loan from 2/6-2014"
        status.icon.must_equal "icon-minus-circle"
        status.callno.must_equal "543.3 Standard"
        status.url.must_equal "http://example.com/123456789"
        status.count.must_equal 1

        result.first.summary.must_equal status
      end
      aleph.errback do |error|
        flunk error
      end
    end
  end

  it "merges identical items" do

    EM.run_block do
      reference = Reference.new(params)
      stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/aleph_000150419.txt"))
      aleph = Aleph.new(reference, configuration)
      aleph.callback do |result|
        result.first.locations.size.must_equal 1
        result.first.locations.first.last.size.must_equal 1

        status = result.first.locations.first.last.first
        status.text.must_equal "Available on-site"
        status.icon.must_equal "icon-home"
        status.callno.must_equal ""
        status.count.must_equal 24

        result.first.summary.must_equal status
      end
      aleph.errback do |error|
        flunk error
      end
    end
  end

  it "handles items that are out on loan and reserved" do
    EM.run_block do
      reference = Reference.new(params)
      stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/aleph_000590035.txt"))
      aleph = Aleph.new(reference, configuration)
      aleph.callback do |result|
        result.first.locations.size.must_equal 1
        result.first.locations.first.last.size.must_equal 2

        first_status = result.first.locations["DTU Ballerup"].first
        first_status.text.must_equal "Available on-site"
        first_status.icon.must_equal "icon-home"
        first_status.callno.must_equal "621.3 HAM"
        first_status.count.must_equal 1

        second_status = result.first.locations["DTU Ballerup"].last
        second_status.text.must_equal "Unavailable"
        second_status.icon.must_equal "icon-minus-circle"
        second_status.callno.must_equal "621.3 HAM"
        second_status.url.must_equal "http://example.com/123456789"
        second_status.count.must_equal 1

        result.first.summary.must_equal first_status
      end
      aleph.errback do |error|
        flunk error
      end
    end
  end

  it "sets the earliest due date" do
    EM.run_block do
      reference = Reference.new(params)
      stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/aleph_000588570.txt"))
      aleph = Aleph.new(reference, configuration)
      aleph.callback do |result|
        result.first.locations.size.must_equal 1
        result.first.locations.first.last.size.must_equal 1

        status = result.first.locations["DTU Ballerup"].first
        status.text.must_equal "Available from 20/5-2014"
        status.text_long.must_equal "Available for loan from 20/5-2014"
        status.icon.must_equal "icon-minus-circle"
        status.callno.must_equal "621.3.01 HAM"
        status.url.must_equal "http://example.com/123456789"
        status.count.must_equal 3

        result.first.summary.must_equal status
      end
    end
  end

  it "handles lending period which indicates on-site use" do
    EM.run_block do
      reference = Reference.new(params)
      stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/aleph_000257963.txt"))
      aleph = Aleph.new(reference, configuration)
      aleph.callback do |result|
        result.first.locations.size.must_equal 1
        result.first.locations.first.last.size.must_equal 1

        status = result.first.locations["DTU Lyngby"].first
        status.text.must_equal "Available on-site"
        status.icon.must_equal "icon-home"
        status.callno.must_equal "536.7 Experimental"
        status.count.must_equal 1

        result.first.summary.must_equal status
      end
    end
  end

  it "handles in order items" do
    EM.run_block do
      reference = Reference.new(params)
      stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/aleph_000594157.txt"))
      aleph = Aleph.new(reference, configuration)
      aleph.callback do |result|
        result.first.locations.size.must_equal 1
        result.first.locations.first.last.size.must_equal 1

        status = result.first.locations["DTU Ballerup"].first
        status.text.must_equal "Unavailable"
        status.icon.must_equal "icon-minus-circle"
        status.callno.must_equal "i bestilling"
        status.url.must_equal "http://example.com/123456789"
        status.count.must_equal 1

        result.first.summary.must_equal status
      end
    end
  end

  it "handles lending period which indicates unavailability" do
    EM.run_block do
      reference = Reference.new(params)
      stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/aleph_000108988.txt"))
      aleph = Aleph.new(reference, configuration)
      aleph.callback do |result|
        result.first.locations.size.must_equal 1
        result.first.locations.first.last.size.must_equal 2

        first_status = result.first.locations["DTU Lyngby"].first
        first_status.text.must_equal "Unavailable"
        first_status.icon.must_equal "icon-minus-circle"
        first_status.callno.must_equal "669 Jen"
        first_status.url.must_equal "http://example.com/123456789"
        first_status.count.must_equal 1

        second_status = result.first.locations["DTU Lyngby"].last
        second_status.text.must_equal "Available"
        second_status.text_long.must_equal "Available for loan"
        second_status.icon.must_equal "icon-check"
        second_status.url.must_equal "http://example.com/123456789"
        second_status.callno.must_equal "669 Jen"
        second_status.count.must_equal 1

        result.first.summary.must_equal second_status
      end
    end
  end

  it "handles lending period which indicates unavailability" do
    EM.run_block do
      reference = Reference.new(params)
      stub_request(:get, /#{configuration['url']}.*/).to_return(File.new("spec/fixtures/aleph_000255716.txt"))
      aleph = Aleph.new(reference, configuration)
      aleph.callback do |result|
        result.first.locations.size.must_equal 1
        result.first.locations.first.last.size.must_equal 1

        status = result.first.locations["DTU Lyngby"].first
        status.text.must_equal "Unavailable"
        status.icon.must_equal "icon-minus-circle"
        status.callno.must_equal "Bestilt 1 eks. 980511"
        status.url.must_equal "http://example.com/123456789"
        status.count.must_equal 1

        result.first.summary.must_equal status
      end
    end
  end

end
