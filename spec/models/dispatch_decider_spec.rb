
require_relative '../test_helper'

describe DispatchDecider do

  it "ignores the scan response" do
    dd = DispatchDecider.new("fulltext", "dtu_staff")
    dd.status.mark_no_response("metastore")
    
    scan_rep = ServiceResponse.new
    scan_rep.service_type = "fulltext"
    scan_rep.subtype = "rd_scan"
    scan_rep.source = "scan"
    scan_rep.priority = 3

    sfx_rep = ServiceResponse.new
    sfx_rep.service_type = "fulltext"
    sfx_rep.subtype = "license"
    sfx_rep.source = "sfx"
    sfx_rep.priority=2

    dd.can_send(scan_rep).must_equal(:maybe)
    dd.can_send(sfx_rep).must_equal(:yes)
  end

  it "only selects the license result" do
    dd = DispatchDecider.new("fulltext_short", "dtu_staff")

    metastore_rep = ServiceResponse.new
    metastore_rep.service_type = "fulltext"
    metastore_rep.subtype = "openaccess"
    metastore_rep.source = "metastore"
    metastore_rep.priority = 1

    sfx_rep = ServiceResponse.new
    sfx_rep.service_type = "fulltext"
    sfx_rep.subtype = "license"
    sfx_rep.source = "sfx"
    sfx_rep.priority=2

    metastore_can_send = dd.can_send(metastore_rep)
    metastore_can_send.must_equal(:maybe)
    dd.status.update(metastore_rep, metastore_can_send == :yes)
    dd.can_send(sfx_rep).must_equal(:yes)
  end

end