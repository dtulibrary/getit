# TODO: Remove this class when all environments have their configs updated
#       to not use the 'Scan' service
class Scan
  include Service

  def parse_response(response)
    []
  end

  def response_alternative
    []
  end

  def get_query
    nil
  end
end
