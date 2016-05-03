class HoldingsEndpoint
  attr_accessor :year, :volume, :issue

  def initialize args
    @year   = args[:year]   if args[:year]
    @volume = args[:volume] if args[:volume]
    @issue  = args[:issue]  if args[:issue]
  end

  def before(endpoint)
  end
end
