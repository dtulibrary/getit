class DticScan
  class HoldingsInterval
    attr_accessor :type, :from, :to

    def initialize(args)
      @type = args['type']
      @from = HoldingsPoint.new(args, 'from') if HoldingsPoint.valid?(args, 'from')
      @to   = HoldingsPoint.new(args, 'to')   if HoldingsPoint.valid?(args, 'to')
    end

    def include?(holdings_point)
      case
      when :from && :to
        from <= holdings_point && holdings_point <= to
      when :from
        from <= holdings_point
      when :to
        holdings_point <= to
      end
    end

    def to_s
      "#{type}: #{from} - #{to}"
    end
  end
end
