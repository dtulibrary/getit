
module ApplicationHelper  
  
  def title(value = nil)
    @title = value if value
    @title ? "GetIt - #{@title}" : "GetIt" 
  end

  def t(*args)
    I18n.t(*args)
  end

  def get_class(class_name)    
    begin
      klass = Module.const_get(class_name)
      return klass.is_a?(Class) ? klass : nil
    rescue NameError      
      nil
    end    
  end
end