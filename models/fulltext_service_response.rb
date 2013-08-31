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

  def initialize
    super
    @public_vars.concat(["@short_name", "@type", "@short_explanation", "@lead_text", "@explanation", 
      "@button_text", "@tool_tip", "@icon"])
  end

end