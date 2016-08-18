class Document
  attr_accessor :solr_doc

  def initialize(solr_doc_json)
    @solr_doc = solr_doc_json
  end

  def english?
    !undefined_language? && lang_field.start_with?('eng')
  end

  def undefined_language?
    lang_field.nil? || lang_field.empty? || lang_field.start_with?('und')
  end

  def conference_paper?
    solr_doc['subformat_s'] == 'conference_paper'
  end

  private

  def lang_field
    (solr_doc['isolanguage_ss'] || []).first
  end
end
