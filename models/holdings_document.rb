class HoldingsDocument

  def initialize(doc)
    @doc = doc
  end

  def holdings_intervals
    @intervals ||= (@doc['holdings_ssf'] || []).map {|json| HoldingsInterval.new(JSON.parse(json))}
  end

  def printed_holdings
    @printed ||= holdings_intervals.select {|interval| interval.type == 'printed'}
  end

  def electronic_holdings
    @electronic ||= holdings_intervals.select {|interval| interval.type == 'electronic'}
  end

  def to_s
    holdings_intervals.join("\n")
  end
end
