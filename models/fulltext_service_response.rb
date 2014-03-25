require_relative 'service_response'

class FulltextServiceResponse < ServiceResponse

  attr_accessor :short_name
  attr_accessor :type
  attr_accessor :short_explanation
  attr_accessor :lead_text
  attr_accessor :explanation
  attr_accessor :button_text
  attr_accessor :tool_tip
  attr_accessor :icon
  attr_accessor :holdings_list
  attr_accessor :list_text

  def initialize
    super
    @public_vars.concat(["@short_name", "@type", "@short_explanation", "@lead_text", "@explanation",
      "@button_text", "@tool_tip", "@icon", "@holdings_list", "@list_text"])
    @holdings_list = Array.new
  end

  def set_translations(doc_type, sub_type, user_type)
    lookup_text = "fulltext.#{doc_type}.#{sub_type}.%s.#{user_type}"

    set_translation("short_name", lookup_text)
    set_translation("type", lookup_text)
    set_translation("short_explanation",  lookup_text)
    set_translation("lead_text",  lookup_text)
    set_translation("explanation",  lookup_text)
    set_translation("button_text",  lookup_text)
    set_translation("tool_tip",  lookup_text)
    set_translation("icon",  lookup_text)
    set_translation("list_text",  lookup_text)
  end

end