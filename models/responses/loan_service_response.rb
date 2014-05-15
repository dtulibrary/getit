
class LoanServiceResponse < ServiceResponse

  # summary of the best option from location_list
  attr_accessor :summary
  # {location => [status1, status2, ..], ...}
  attr_accessor :locations

  def initialize
    super
    @public_vars << "@summary" << "@locations"
    @locations = Hash.new
    @summary = Status.new
  end

  class Status
    include Comparable

    attr_accessor :availability
    attr_accessor :icon
    attr_accessor :icon_color
    attr_accessor :text
    attr_accessor :text_long
    attr_accessor :url
    attr_accessor :url_text
    attr_accessor :count
    attr_accessor :callno
    attr_accessor :due_date

    @@availabilities = {:available => 3, :available_onsite => 2, :unavailable => 1}
    @@availabilities.default = 0

    def self.availabilities
      @@availabilities
    end

    def initialize
      @count = 1
    end

    def to_json(*a)
      status_map = {}
      status_map["icon"] = self.icon unless self.icon.nil?
      status_map["icon_color"] = self.icon_color unless self.icon_color.nil?
      status_map["text"] = self.text unless self.text.nil?
      status_map["text_long"] = self.text_long unless self.text_long.nil?
      status_map["url"] = self.url unless self.url.nil?
      status_map["url_text"] = self.url_text unless self.url_text.nil?
      status_map["count"] = self.count unless self.count.nil?
      status_map["callno"] = self.callno unless self.callno.nil? || self.availability == :unavailable
      status_map.to_json(*a)
    end
  end
end
