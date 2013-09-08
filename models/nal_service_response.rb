require_relative 'fulltext_service_response'

class NalServiceResponse < FulltextServiceResponse

  attr_accessor :url_list

  def initialize
    super    
    @public_vars << "@url_list"
    @url_list = Hash.new
  end
end