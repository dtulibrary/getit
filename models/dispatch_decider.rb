
require_relative 'rules'

class DispatchDecider
  include Rules

  attr_accessor :status

  def initialize(service_list_name, user_type)

    @status = Status.new    
    @rules = []

    if(service_list_name.eql?("fulltext"))
      add_fulltext_rules(user_type)
    else
      if(service_list_name.eql?("fulltext_short"))
        add_fulltext_short_rules(user_type)
      end
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

      if(test != :yes)
        result = test
        if(result == :no)
          break
        end
      end
    end
    result
  end

  class Status
    attr_accessor :count
    attr_accessor :seen

    def initialize
      @count = 0
      @seen = {}
    end

    def update(result, has_sent)
      if(has_sent)
        @count += 1
        @seen[result.source] = result.subtype    
      else
        @seen[result.source] = -1  
      end
    end

    def mark_no_response(service_name)
      @seen[service_name] = -1
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
      if(reply.call(data, status))
        result = :yes
      elsif(test = skip.call(data, status))
        result = :no
      elsif(wait.call(data, status))        
        result = :maybe
      end
      result
    end
  end
end