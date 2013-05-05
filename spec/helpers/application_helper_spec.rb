
require_relative '../test_helper'

describe ApplicationHelper do

  before do
    @test = Object.new
    @test.extend(ApplicationHelper)
  end

  describe "get_class" do

    it "returns nil for non existing class" do      
      @test.get_class("abc").must_be_nil
    end

    it "returns class for existing class" do
      @test.get_class("Metastore").wont_be_nil
    end
  end

end