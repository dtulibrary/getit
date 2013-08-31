
require_relative 'rules'

class DispatchDecider
  include Rules

  attr_accessor :status

  def initialize(service_list_name, reference)

    @reference = reference
    @status = Status.new    
    @rules = []

    case service_list_name
    when "fulltext"
      if @reference.doctype == "article"
        add_fulltext_rules 
      end
    when "fulltext_info"
      if @reference.doctype == "article"
        add_fulltext_info_rules
      end
    when "fulltext_short"
      add_fulltext_short_rules(@reference.doctype)
    end
  end

  def can_send(response)    
    process_rules(response)
  end

  private

  def rule(name, options = {})
    @rules << Rule.new(name, options)
  end

  # process all rules
  # a rule test can respond with :yes, :no or :undecided
  # :undecided is used when there is not enough info to decide yet
  # Truth table for comining rules:
  #   
  # __|_y_|_u_|_n_
  # y | y   u   n
  # u | u   u   n
  # n | n   n   n
  #
  def process_rules(data)
    result = :yes
    @rules.sort_by(&:priority).each do |rule|    
      test = rule.run(data, @status)
      if test != :yes
        result = test
        if result == :no
          break
        end
      end
    end
    result
  end

  class Status
    attr_accessor :count
    attr_accessor :sent
    attr_accessor :onhold
    attr_accessor :ignore
    attr_accessor :responses

    def initialize
      @count = 0
      @sent, @onhold = {}, {}
      @ignore, @responses = [], []
    end

    def update(response, status)
      case status
      when :yes
        @sent[response.source] = response.subtype
        @responses << response
        @count += 1
      when :maybe
        @onhold[response.source] = response.subtype
      else
        @ignore << response
      end
    end
    
    def seen
      @sent.keys + @onhold.keys + @ignore
    end

    def seen_with_subtype
      @sent.merge(@onhold)
    end    
  end

  class Rule

    attr_accessor :priority
    attr_accessor :name
    attr_accessor :reply
    attr_accessor :skip
    attr_accessor :wait

    NO_OP = lambda {|*o| false }

    def initialize(name, options={})
      self.name = name
      self.priority = options[:priority] || 10
      self.reply = options[:reply] || NO_OP
      self.skip = options[:skip] || NO_OP
      self.wait = options[:wait] || NO_OP
    end

    def run(data, status)
      result = :yes      
      if evaluate(reply, data)
        result = :yes
      elsif evaluate(skip, data)
        result = :no
      elsif evaluate(wait, data)
        result = :maybe
      end
      result
    end

    private 

    def evaluate(predicates, data)
      if !predicates.is_a?(Array)
        predicates = [predicates]
      end
      predicates.each do |predicate|
        res = predicate.call(data)
        return true if res
      end
      return false      
    end
  end
end