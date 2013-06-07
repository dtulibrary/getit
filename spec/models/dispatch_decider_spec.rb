require_relative '../test_helper'

describe DispatchDecider do

  params = {
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

  it "ignores the scan response" do

    reference = Reference.new(params.merge({"req_id" => "dtu_staff"}))
    dd = DispatchDecider.new("fulltext", reference)
    dd.status.update("metastore", :no)
    
    scan_rep = ServiceResponse.new
    scan_rep.service_type = "fulltext"
    scan_rep.subtype = "rd_scan"
    scan_rep.source = "scan"

    sfx_rep = ServiceResponse.new
    sfx_rep.service_type = "fulltext"
    sfx_rep.subtype = "license"
    sfx_rep.source = "sfx"

    dd.can_send(scan_rep).must_equal(:maybe)
    dd.can_send(sfx_rep).must_equal(:yes)
  end

  it "only selects the license result" do

    reference = Reference.new(params.merge({"req_id" => "dtu_staff"}))
    dd = DispatchDecider.new("fulltext_short", reference)

    metastore_rep = ServiceResponse.new
    metastore_rep.service_type = "fulltext"
    metastore_rep.subtype = "openaccess"
    metastore_rep.source = "metastore"

    sfx_rep = ServiceResponse.new
    sfx_rep.service_type = "fulltext"
    sfx_rep.subtype = "license"
    sfx_rep.source = "sfx"

    metastore_can_send = dd.can_send(metastore_rep)
    metastore_can_send.must_equal(:maybe)
    dd.status.update(metastore_rep.source, metastore_can_send, metastore_rep.subtype)
    dd.can_send(sfx_rep).must_equal(:yes)
  end

  it "only selects the scan result" do

    reference = Reference.new(params.merge({"req_id" => "anonymous"}))
    dd = DispatchDecider.new("fulltext_short", reference)
    dd.status.update("sfx", :no)

    metastore_rep = ServiceResponse.new
    metastore_rep.service_type = "fulltext"
    metastore_rep.subtype = "license"
    metastore_rep.source = "metastore"

    scan_rep = ServiceResponse.new
    scan_rep.service_type = "fulltext"
    scan_rep.subtype = "dtic_scan"
    scan_rep.source = "scan"

    metastore_can_send = dd.can_send(metastore_rep)
    metastore_can_send.must_equal(:maybe)
    dd.status.update(metastore_rep.source, metastore_can_send, metastore_rep.subtype)
    dd.can_send(scan_rep).must_equal(:yes)
  end
end