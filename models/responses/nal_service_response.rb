
class NalServiceResponse < FulltextServiceResponse

  attr_accessor :url_list
  attr_accessor :urls

  def initialize
    super
    @public_vars << "@url_list" << "@urls"
    @url_list = Hash.new
    @urls = []
  end
end
