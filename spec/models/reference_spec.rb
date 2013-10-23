require_relative '../test_helper'

describe Reference do
 
  it "creates a context object with multiple ids" do    
    query_string = "url_ver=Z39.88-2004&url_ctx_fmt=info:ofi/fmt:kev:mtx:ctx&ctx_ver=Z39.88-2004&ctx_enc=info:ofi/enc:UTF-8&rft.genre=book&rft.btitle=Micro process engineering : a comprehensive handbook&rft.au=Hessel, Volker.&rft.date=2009&rft.isbn=9783527315505&rft_val_fmt=info:ofi/fmt:kev:mtx:book&rft_id=urn:isbn:3527631445&rft_id=urn:isbn:3527315500&rft_id=urn:isbn:9783527631445&rft_id=urn:isbn:9783527315505"
    
    reference = Reference.new(CGI::parse(query_string))
    reference.context_object.referent.identifiers.length.must_equal 4
  end

end