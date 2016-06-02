class HoldingsPoint
  include Comparable

  attr_accessor :type, :year, :volume, :issue

  def initialize(args, type = '')
    @type   = type
    @year   = args["#{type}year"]
    @volume = args["#{type}volume"]
    @issue  = args["#{type}issue"]
  end

  def <=>(other)
    # Find the first element that is non-nil in both objects and differs between the
    # objects. Use that element as the basis for comparable.
    [:year, :volume, :issue].reject {|e| self.send(e).nil? || other.send(e).nil?}
                            .reject {|e| self.send(e) == other.send(e)}
                            .map    {|e| self.send(e).to_s <=> other.send(e).to_s}
                            .first || 0 # Assumes self.valid?
  end

  def to_s
    "(#{[:year, :volume, :issue].reject {|e| e.nil?}.join(',')})"
  end

  def self.valid?(args, type)
    ['year', 'volume', 'issue'].any? {|e| args["#{type}#{e}"]}
  end

end
