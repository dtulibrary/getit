require 'nokogiri'
require_relative 'service'

class Sfx
  include Service

  def initialize(reference, configuration, cache_settings = {})    
    # mapping of service type names between SFX and GetIT
    @sfx_to_getit_types = {"getFullTxt" => "fulltext"}

    @sfx_target_priority = {
      "EBSCOHOST_ACADEMIC_SEARCH_ELITE" => 1,       
      "EBSCOHOST_BUSINESS_SOURCE_PREMIER" => 1,
      "JSTOR_ARTS_AND_SCIENCES_1" => 1,
      "JSTOR_LIFE_SCIENCES_COLLECTION" => 1,
      "JSTOR_EARLY_JOURNAL_CONTENT_FREE" => 1,  
      "DOAJ_DIRECTORY_OPEN_ACCESS_JOURNALS_FREE" => 1,
      "MISCELLANEOUS_FREE_EJOURNALS" => 1    
    }
    @sfx_target_priority.default = 0
    
    skip = reference.doctype == 'book' &&
      reference.context_object.referent.metadata['isbn'].nil? && 
      reference.context_object.referent.metadata['issn'].nil? 

    if skip
      # do not check for books without isbn
      # to prevent wrong matches on title
      self.succeed([])
    else
      super(reference, configuration, cache_settings)
    end

  end

  def parse_response

    service_responses = []
    doc = Nokogiri::XML(@response[:body])     

    unless doc.at('/ctx_obj_set')      
      return []
    end

    # multiple context objects can be returned
    sfx_objs = doc.search('/ctx_obj_set/ctx_obj')

    sfx_objs.each do |context_object| 

      context_object.search('./ctx_obj_targets/target').each do |target|

        service_type = target.at("./service_type").inner_text

        if @configuration["service_types"].include?(@sfx_to_getit_types[service_type])

          response = FulltextServiceResponse.new
          response.url = target.at("./target_url").inner_text.chomp("/")
          response.service_type = @sfx_to_getit_types[service_type]
          response.source = "sfx"
          response.priority = @sfx_target_priority[target.at("./target_name").inner_text]

          if (target/"./target_public_name").inner_text =~ /open access/i
            response.subtype = "openaccess_remote"
          else
            response.subtype = "license_remote"
          end

          if response.subtype.start_with?("license") && @reference.user_type == "public"
            response.url = "http://www.dtic.dtu.dk/english/servicemenu/visit/opening#lyngby"
          end

          lookup_text = "fulltext.#{@reference.doctype}.#{response.subtype}.%s.#{@reference.user_type}"

          response.short_name = I18n.t lookup_text % "short_name"
          response.type = I18n.t lookup_text % "type"
          response.short_explanation = I18n.t lookup_text % "short_explanation"
          response.lead_text = I18n.t lookup_text % "lead_text"
          response.explanation = I18n.t lookup_text % "explanation"
          response.button_text = I18n.t lookup_text % "button_text"
          response.tool_tip = I18n.t lookup_text % "tool_tip"
          response.icon = I18n.t lookup_text % "icon"          

          # only include response if it's not a duplicate (i.e. different target names but identical URLs)
          if !duplicate?(response, service_responses)
            service_responses << response
          end
        end
      end
    end

    # sort and return, max one open access & one licensed
    sr_licensed, sr_openaccess = service_responses.partition {|sr| sr.subtype == "license"}
    service_responses = []
    service_responses << sr_licensed.sort_by(&:priority).first if !sr_licensed.nil? && !sr_licensed.empty?
    service_responses << sr_openaccess.sort_by(&:priority).first if !sr_openaccess.nil? && !sr_openaccess.empty?
    service_responses
  end

  def get_query    
    co = @reference.clean_context_object
    co.serviceType.push(OpenURL::ContextObjectEntity.new) if co.serviceType.length == 0
    @sfx_to_getit_types.values.each do |service_type|
      co.serviceType.first.set_metadata(service_type, "yes")
    end    
    co_h = co.to_hash.merge({"req.ip" => "127.0.0.1", "sfx.response_type" => "multi_obj_xml"})
    # remove timestamp so it can be used as cache key    
    co_h.delete("ctx_tim")
    if @reference.doctype == "journal"
      co_h["sfx.ignore_date_threshold"] = 1
    end
    co_h
  end

  private

  def duplicate?(response, service_responses)
    service_responses.select { |r| r.url == response.url && r.service_type == response.service_type }.size > 0   
  end

end