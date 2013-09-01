
require 'json'

class ServiceResponse

  attr_accessor :url
  attr_accessor :service_type
  attr_accessor :subtype
  attr_accessor :source  
  attr_accessor :priority
  attr_accessor :source_priority

  def initialize
    @public_vars = ["@url", "@service_type", "@subtype", "@source"]
  end

  def to_json
    sr_map = {}
    self.instance_variables.each do |var|
      if(instance_variable_defined?(var) && @public_vars.include?(var.to_s))
        sr_map[var_name(var)] = self.instance_variable_get(var.to_s)
      end      
    end
    sr_map.to_json
  end

  private

  def var_name(var)
    var.to_s.sub(/^@/, "")
  end

end 