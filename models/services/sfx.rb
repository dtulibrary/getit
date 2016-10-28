require 'nokogiri'

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

    # Using the DOI in link resolution for journals leads to problems
    # with invalid target_urls being returned
    if reference.doctype == 'journal'
      reference.context_object.referent.set_metadata('doi', '')
    end

    if skip
      # do not check for books without isbn
      # to prevent wrong matches on title
      self.succeed([])
    else
      super(reference, configuration, cache_settings)
    end

  end

  def parse_response(response)

    service_responses = []
    doc = Nokogiri::XML(response[:body])

    if doc.at('/ctx_obj_set')
      # response type multi_obj_xml
      node_list = doc.search('/ctx_obj_set/ctx_obj/ctx_obj_targets/target')
    elsif doc.at('/sfx_menu')
      # response type simplexml
      node_list = doc.search('/sfx_menu/targets/target')
    else
      node_list = []
    end

    node_list.each do |target|

      response = parse_target(target)

      # only include response if it's not a duplicate (i.e. different target names but identical URLs)
      if !duplicate?(response, service_responses)
        service_responses << response
      end
    end

    # sort and return, max one open access & one licensed
    if @reference.doctype != 'journal'
      sr_licensed, sr_openaccess = service_responses.partition {|sr| sr.subtype.match("license") }
      service_responses = []
      service_responses << sr_licensed.sort_by(&:priority).first if !sr_licensed.nil? && !sr_licensed.empty?
      service_responses << sr_openaccess.sort_by(&:priority).first if !sr_openaccess.nil? && !sr_openaccess.empty?
    end

    service_responses
  end

  def parse_target(target)

    service_type = target.at("./service_type").inner_text

    response = FulltextServiceResponse.new
    response.url = target.at("./target_url").inner_text.chomp("/")
    response.service_type = @sfx_to_getit_types[service_type]
    response.source = "sfx"
    response.source_priority = @configuration["priority"]
    response.priority = @sfx_target_priority[target.at("./target_name").inner_text]
    response.log_info = "SFX target: #{target.at("./target_name").inner_text}"

    if (target/"./target_public_name").inner_text =~ /open access/i
      response.subtype = "openaccess_remote"
    else
      response.subtype = "license_remote"
    end

    if response.subtype.start_with?("license") && @reference.user_type == "public"
      response.url = "http://www.dtic.dtu.dk/english/servicemenu/visit/opening#lyngby"
    end

    unless (target/"./coverage").nil?

      (target/"./coverage").each do |coverage|

        # iterate over holdings sequentially
        # comes in the form from - to - from - to

        holding = {}
        coverage.children.each do |node|

          if node.name == "from" && !holding.empty?
            response.holdings_list << holding
            holding = {}
          end
          if node.name == "from" || node.name == "to"
            node.children.each do |child|
              holding["#{node.name}#{child.name}"] = child.content unless child.name == "text"
            end
          end
        end
        response.holdings_list << holding unless holding.empty?

        unless (coverage/"./embargo/availability").nil?
          if (coverage/"./embargo/availability").inner_text == "not_available"

            (coverage/"./embargo").children.each do |node|
              if ["year", "month"].include? node.name
                response.holdings_list << { "embargo" => [ node.name, node.content]}
                break
              end
            end
          end
        end
      end
    end

    response.set_translations(@reference.doctype, response.subtype, @reference.user_type)

    response
  end

  def get_query
    queries = []

    co = @reference.clean_context_object

    co.serviceType.push(OpenURL::ContextObjectEntity.new) if co.serviceType.length == 0
    @sfx_to_getit_types.values.each do |service_type|
      co.serviceType.first.set_metadata(service_type, "yes")
    end

    co_h = co.to_hash

    # remove timestamp so it can be used as cache key
    co_h.delete("ctx_tim")

    if @reference.doctype == "journal"
      co_h["sfx.ignore_date_threshold"] = 1
      co_h["sfx.show_availability"] = 1
      co_h["sfx.response_type"] = "multi_obj_xml"
    else
      # the multi_obj_xml response type does not resolve for all articles and books
      # but the simplexml response type does not include coverage for journals
      co_h["sfx.response_type"] = "simplexml"
    end

    # collect standard numbers (issn+isbn) to identify if multiple queries should be created,
    # one for each number
    standard_numbers = {}
    if co_h.key? 'rft_id'

      ids = (co_h['rft_id'].is_a? Array) ? co_h['rft_id'] : [co_h['rft_id']]
      ids.each do |id|
        if m = /urn:isbn:(.*)/.match(id)
          standard_numbers[m[1]] = :isbn
        elsif m = /urn:issn:(.*)/.match(id)
          standard_numbers[m[1]] = :issn
        end
      end
    end

    # create a query for each of the issns/isbns
    if standard_numbers.empty?
      queries << URI.escape(flatten_params(co_h).join('&'))
    else
      co_h.delete("rft.isbn")
      co_h.delete("rft.issn")
      params = flatten_params(co_h)

      standard_numbers.sort.map do |number, type|
        query_params = params.dup
        query_params << "rft.#{type.to_s}=#{number}"
        queries << URI.escape(query_params.join('&'))
      end
    end

    queries.map! {|query| "#{query}&fromfindit=true"}

    queries
  end

  private

  def flatten_params(params)
    params.collect do |k, v|
      # flatten array params
      if v.is_a? Array
        v.collect{|e| "#{k}=#{e}"}.join('&')
      else
        "#{k}=#{v}"
      end
    end
  end

  def duplicate?(response, service_responses)
    service_responses.select { |r| r.url == response.url && r.service_type == response.service_type }.size > 0
  end

end
