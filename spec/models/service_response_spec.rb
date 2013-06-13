require_relative '../test_helper'

describe ServiceResponse do

  it "exports to json correct" do
    url = "http://example.com"
    s = ServiceResponse.new
    s.url = url
    s.text = "Some link text" 
    sj = JSON.parse(s.to_json)
    sj["url"].must_equal(url)
  end

end