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

  it 'prefers SFX licensed fulltext over scans for DTU users' do
    reference = Reference.new(params.merge('req_id' => 'dtu_staff'))

    dd = DispatchDecider.new("fulltext", reference)
    dd.status.update("metastore", :no)
    
    sfx       = fulltext_response('sfx', 'license_remote')
    dtic_scan = fulltext_response('dtic_scan')
    tib_scan  = fulltext_response('tib_scan')
    rd_scan   = fulltext_response('rd_scan')

    dd.status.update(sfx, :yes)

    dd.can_send(dtic_scan).must_equal(:no)
    dd.can_send(tib_scan).must_equal(:no)
    dd.can_send(rd_scan).must_equal(:no)
  end

  it 'prefers openaccess fulltext over scans for public users' do
    reference = Reference.new(params.merge('req_id' => 'public'))

    metastore = fulltext_response('metastore', 'openaccess_local')
    sfx       = fulltext_response('sfx', 'license_remote')

    dd = DispatchDecider.new('fulltext', reference)
    dd.status.update(metastore, dd.can_send(metastore))
    dd.status.update(sfx, dd.can_send(sfx))

    dd.can_send(fulltext_response('dtic_scan')).must_equal(:no)
  end

  it 'prefers dtic scan over licensed fulltexts for public users' do
    reference = Reference.new(params.merge('req_id' => 'public'))

    metastore = fulltext_response('metastore', 'license_remote')
    sfx       = fulltext_response('sfx', 'license_remote')
    dtic_scan = fulltext_response('dtic_scan')

    dd = DispatchDecider.new('fulltext', reference)
    dd.status.update(metastore, :yes)
    dd.status.update(sfx, :yes)

    dd.can_send(dtic_scan).must_equal(:yes)
  end

  it 'prefers rd scan over licensed fulltexts for public users' do
    reference = Reference.new(params.merge('req_id' => 'public'))

    metastore = fulltext_response('metastore', 'license_remote')
    sfx       = fulltext_response('sfx', 'license_remote')
    dtic_scan = fulltext_response('dtic_scan')
    rd_scan   = fulltext_response('rd_scan')

    dd = DispatchDecider.new('fulltext', reference)
    dd.status.update(metastore, :yes)
    dd.status.update(sfx, :yes)
    dd.status.update(dtic_scan, :no)

    dd.can_send(rd_scan).must_equal(:yes)
  end

  it 'prefers dtic scan over rd scan for public users' do
    reference = Reference.new(params.merge('req_id' => 'public'))

    metastore = fulltext_response('metastore', 'license_remote')
    sfx       = fulltext_response('sfx', 'license_remote')
    dtic_scan = fulltext_response('dtic_scan')
    rd_scan   = fulltext_response('rd_scan')

    dd = DispatchDecider.new('fulltext', reference)
    dd.status.update(metastore, :yes)
    dd.status.update(sfx, :yes)
    dd.status.update(dtic_scan, :yes)

    dd.can_send(rd_scan).must_equal(:no)
  end

  it 'prefers dtic scan over tib scan for DTU users' do
    reference = Reference.new(params.merge({"req_id" => "dtu_staff"}))

    metastore = fulltext_response('metastore')
    sfx       = fulltext_response('sfx')
    dtic_scan = fulltext_response('dtic_scan')
    tib_scan  = fulltext_response('tib_scan')

    dd = DispatchDecider.new("fulltext", reference)
    dd.status.update(metastore, :no)
    dd.status.update(sfx, :no)
    dd.status.update(dtic_scan, :yes)

    dd.can_send(tib_scan).must_equal(:no)
  end

  it 'prefers tib scan over rd scan for DTU users' do
    reference = Reference.new(params.merge({"req_id" => "dtu_staff"}))

    dd = DispatchDecider.new("fulltext", reference)
    dd.status.update('metastore', :no)
    dd.status.update('sfx', :no)
    dd.status.update('dtic_scan', :no)
    dd.status.update(fulltext_response('tib_scan'), :yes)

    rd = fulltext_response('rd_scan')

    dd.can_send(rd).must_equal(:no)
  end

  it 'prefers rd scan over nothing for DTU users' do
    reference = Reference.new(params.merge({"req_id" => "dtu_staff"}))

    dd = DispatchDecider.new("fulltext", reference)
    dd.status.update('metastore', :no)
    dd.status.update('sfx', :no)
    dd.status.update('dtic_scan', :no)
    dd.status.update('tib_scan', :no)

    rd = fulltext_response('rd_scan')

    dd.can_send(rd).must_equal(:yes)
  end

  it "only selects the license result" do
    reference = Reference.new(params.merge({"req_id" => "dtu_staff"}))

    metastore = fulltext_response('metastore', 'openaccess_local')
    sfx       = fulltext_response('sfx', 'license_remote')

    dd = DispatchDecider.new("fulltext_short", reference)

    dd.can_send(metastore).must_equal(:maybe)
    dd.status.update(metastore, :maybe)
    dd.can_send(sfx).must_equal(:yes)
    dd.status.update(sfx, :yes)
    dd.can_send(metastore).must_equal(:no)
  end

  it 'prefers scans over licensed fulltexts on the short fulltext list for public users' do
    reference = Reference.new(params.merge({"req_id" => "anonymous"}))

    metastore = fulltext_response('metastore', 'license_local')
    sfx       = fulltext_response('sfx', 'license_remote')
    dtic_scan = fulltext_response('dtic_scan')

    dd = DispatchDecider.new("fulltext_short", reference)

    dd.can_send(metastore).must_equal(:maybe)
    dd.status.update(metastore, :maybe)
    dd.status.update(sfx, :no)

    dd.can_send(dtic_scan).must_equal(:yes)
  end

  it "only selects one license result for public users" do
    reference = Reference.new(params.merge({"req_id" => "anonymous"}))

    metastore = fulltext_response('metastore', 'license_local')
    sfx       = fulltext_response('sfx', 'license_remote')

    dd = DispatchDecider.new("fulltext", reference)

    dd.can_send(sfx).must_equal(:maybe)
    dd.status.update(sfx, :maybe)

    dd.can_send(metastore).must_equal(:yes)
    dd.status.update(metastore, :yes)

    dd.can_send(sfx).must_equal(:no)
  end

  it "shows nal if no open access" do
    reference = Reference.new(params.merge({"req_id" => "anonymous"}))

    metastore = fulltext_response('metastore', 'license_local')
    sfx       = fulltext_response('sfx', 'license_remote')
    nal       = fulltext_response('nal')

    dd = DispatchDecider.new("fulltext", reference)

    dd.can_send(metastore).must_equal(:yes)
    dd.status.update(metastore, :yes)

    dd.can_send(sfx).must_equal(:no)
    dd.status.update(sfx, :no)

    dd.can_send(nal).must_equal(:yes)
  end

  def fulltext_response(source, subtype = source)
    response = ServiceResponse.new
    response.service_type = 'fulltext'
    response.source = source
    response.subtype = subtype
    response
  end
end
