class Document
  attr_accessor :solr_doc

  def initialize(solr_doc_json)
    @solr_doc = solr_doc_json
  end

  def english?
    lang_field = solr_doc['language_ss']
    lang_field.nil? || lang_field.empty? || lang_field.include?('eng')
  end

  def undefined_language?
    lang_field = solr_doc['language_ss']
    lang_field.nil? || lang_field.empty? || lang_field.include?('und')
  end

  def conference_paper?
    solr_doc['subformat_s'] == 'conference_paper'
  end
end
