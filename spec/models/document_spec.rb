require_relative '../test_helper'

describe Document do
  describe "undefined_language?" do
    it "returns true when language is nil" do
      (Document.new({}).undefined_language?).must_equal(true)
      (Document.new({"isolanguage_ss" => nil}).undefined_language?).must_equal(true)
    end

    it "returns true when language is an empty string" do
      (Document.new({"isolanguage_ss" => [""]}).undefined_language?).must_equal(true)
    end

    it "returns true when language is 'und'" do
      (Document.new({"isolanguage_ss" => ["und"]}).undefined_language?).must_equal(true)
    end

    it "returns false when language is NOT nil and NOT an empty string" do
      (Document.new({"isolanguage_ss" => ["A"]}).undefined_language?).must_equal(false)
      (Document.new({"isolanguage_ss" => ["B"]}).undefined_language?).must_equal(false)
      (Document.new({"isolanguage_ss" => ["eng"]}).undefined_language?).must_equal(false)
      (Document.new({"isolanguage_ss" => ["ger"]}).undefined_language?).must_equal(false)
    end
  end

  describe "english?" do
    it "returns true when language is 'eng'" do
      (Document.new({"isolanguage_ss" => ["eng"]}).english?).must_equal(true)
    end

    it "returns false when language is 'ger'" do
      (Document.new({"isolanguage_ss" => ["ger"]}).english?).must_equal(false)
    end

    it "returns false when language is 'und'" do
      (Document.new({"isolanguage_ss" => ["ger"]}).english?).must_equal(false)
    end

    it "returns false when language is nil" do
      (Document.new({"isolanguage_ss" => nil}).english?).must_equal(false)
    end

    it "returns false when language is an empty string" do
      (Document.new({"isolanguage_ss" => [""]}).english?).must_equal(false)
    end
  end
end
