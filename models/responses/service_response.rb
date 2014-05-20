
class ServiceResponse

  attr_accessor :url
  attr_accessor :service_type
  attr_accessor :subtype
  attr_accessor :source
  attr_accessor :priority
  attr_accessor :source_priority
  attr_accessor :log_info

  def initialize
    @public_vars = ["@url", "@service_type", "@subtype", "@source"]
  end

  def to_json
    sr_map = {}
    self.instance_variables.each do |var|
      if instance_variable_defined?(var) && @public_vars.include?(var.to_s)
        instance_var = self.instance_variable_get(var.to_s)
        unless instance_var.class == Array && instance_var.empty?
          sr_map[var_name(var)] = instance_var
        end
      end
    end
    sr_map.to_json
  end

  def set_translation(name, translation_key)
    text = I18n.t(translation_key % name, :default => '')
    unless text.empty?
      self.send("#{name}=", text)
    end
  end

  private

  def var_name(var)
    var.to_s.sub(/^@/, "")
  end

end