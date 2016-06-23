require_relative '../test_helper'

describe DispatchDecider do

  params = {
    "url_ver" => "Z39.88-2004",
    "ctx_ver" => "Z39.88-2004",
    "ctx_enc" => "info:ofi/enc:UTF-8",
    "url_ctx_fmt" => "info:ofi/fmt:kev:mtx:ctx",
    "rft_val_fmt" => "info:ofi/fmt:kev:mtx:journal",
    "rft.au" => "Knuth%2C+Donald",
    "rft.atitle" => "Interview%3Cbr+%2F%3EThe+%27art%27+of+being+Donald+Knuth",
    "rft.jtitle" => "Communications+of+the+ACM",
    "rft.issn" => "00010782",
    "rft.issn" => "15577317",
    "rft.date" => "2008",
    "rft.volume" => "51",
    "rft.issue" => "7",
    "rft.pages" => "35-39",
    "rft.doi" => "10.1145%2F1364782.1364794",
    "rft.genre" => "article"
  }

  it "ignores the scan responses" do

    reference = Reference.new(params.merge({"req_id" => "dtu_staff"}))

    dd = DispatchDecider.new("fulltext", reference)
    dd.status.update("metastore", :no)
    
    dtic = scan_response('dtic_scan')
    rd   = scan_response('rd_scan')

    sfx_rep = ServiceResponse.new
    sfx_rep.service_type = "fulltext"
    sfx_rep.subtype = "license_remote"
    sfx_rep.source = "sfx"

    dd.can_send(dtic).must_equal(:maybe)
    dd.can_send(rd).must_equal(:maybe)
    dd.can_send(sfx_rep).must_equal(:yes)
  end

  it 'prefers dtic scan over rd scan' do
    reference = Reference.new(params.merge({"req_id" => "dtu_staff"}))

    dd = DispatchDecider.new("fulltext", reference)
    dd.status.update('metastore', :no)
    dd.status.update('sfx', :no)
    dd.status.update(scan_response('dtic_scan'), :yes)

    rd = scan_response('rd_scan')

    dd.can_send(rd).must_equal(:no)
  end

  it 'prefers rd scan over nothing' do
    reference = Reference.new(params.merge({"req_id" => "dtu_staff"}))

    dd = DispatchDecider.new("fulltext", reference)
    dd.status.update('metastore', :no)
    dd.status.update('sfx', :no)
    dd.status.update('dtic_scan', :no)
    dd.status.update('tib_scan', :no)

    rd  = scan_response('rd_scan')

    dd.can_send(rd).must_equal(:yes)
  end

  it "only selects the license result" do

    reference = Reference.new(params.merge({"req_id" => "dtu_staff"}))
    dd = DispatchDecider.new("fulltext_short", reference)

    metastore_rep = ServiceResponse.new
    metastore_rep.service_type = "fulltext"
    metastore_rep.subtype = "openaccess_local"
    metastore_rep.source = "metastore"

    sfx_rep = ServiceResponse.new
    sfx_rep.service_type = "fulltext"
    sfx_rep.subtype = "license_remote"
    sfx_rep.source = "sfx"

    metastore_can_send = dd.can_send(metastore_rep)
    metastore_can_send.must_equal(:maybe)
    dd.status.update(metastore_rep, metastore_can_send)
    dd.can_send(sfx_rep).must_equal(:yes)
  end

  it "only selects the scan result" do

    reference = Reference.new(params.merge({"req_id" => "anonymous"}))
    dd = DispatchDecider.new("fulltext_short", reference)
    dd.status.update("sfx", :no)

    metastore_rep = ServiceResponse.new
    metastore_rep.service_type = "fulltext"
    metastore_rep.subtype = "license_local"
    metastore_rep.source = "metastore"

    scan_rep = ServiceResponse.new
    scan_rep.service_type = "fulltext"
    scan_rep.subtype = "dtic_scan"
    scan_rep.source = "scan"

    metastore_can_send = dd.can_send(metastore_rep)
    metastore_can_send.must_equal(:maybe)
    dd.status.update(metastore_rep, metastore_can_send)
    dd.can_send(scan_rep).must_equal(:yes)
  end

  it "only selects one license result" do
    reference = Reference.new(params.merge({"req_id" => "anonymous"}))
    dd = DispatchDecider.new("fulltext", reference)

    metastore_rep = ServiceResponse.new
    metastore_rep.service_type = "fulltext"
    metastore_rep.subtype = "license_local"
    metastore_rep.source = "metastore"

    sfx_rep = ServiceResponse.new
    sfx_rep.service_type = "fulltext"
    sfx_rep.subtype = "license_remote"
    sfx_rep.source = "sfx"

    sfx_can_send = dd.can_send(sfx_rep)
    sfx_can_send.must_equal(:maybe)
    dd.status.update(sfx_rep, sfx_can_send)
    metastore_can_send = dd.can_send(metastore_rep)
    metastore_can_send.must_equal(:yes)
    dd.status.update(metastore_rep, metastore_can_send)
    sfx_can_send = dd.can_send(sfx_rep)
    sfx_can_send.must_equal(:no)
  end

  it "shows nal if no open access" do
    reference = Reference.new(params.merge({"req_id" => "anonymous"}))
    dd = DispatchDecider.new("fulltext", reference)

    metastore_rep = ServiceResponse.new
    metastore_rep.service_type = "fulltext"
    metastore_rep.subtype = "license_local"
    metastore_rep.source = "metastore"

    sfx_rep = ServiceResponse.new
    sfx_rep.service_type = "fulltext"
    sfx_rep.subtype = "license_remote"
    sfx_rep.source = "sfx"

    nal_rep = NalServiceResponse.new
    nal_rep.service_type = "fulltext"
    nal_rep.subtype = "nal"
    nal_rep.source = "nal"

    metastore_can_send = dd.can_send(metastore_rep)
    metastore_can_send.must_equal(:yes)
    dd.status.update(metastore_rep, metastore_can_send)
    sfx_can_send = dd.can_send(sfx_rep)
    sfx_can_send.must_equal(:no)
    dd.status.update(sfx_rep, sfx_can_send)
    nal_can_send = dd.can_send(nal_rep)
    nal_can_send.must_equal(:yes)    
  end

  def scan_response(source)
    response = ServiceResponse.new
    response.service_type = "fulltext"
    response.subtype = source
    response.source = source
    response
  end
end
