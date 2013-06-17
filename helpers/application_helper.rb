
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

  def write_response(service_response, reference, prices)
    if service_response.service_type == "fulltext" && service_response.source != "nal" 
      translation_key = "#{service_response.service_type}.#{service_response.subtype}.%s"
      translation_key << ".#{reference.user_type}" if service_response.subtype.eql?("license")
      if service_response.source.eql?("scan")
        price = prices[service_response.subtype][reference.user_type] || -1
        price = "No" if price == 0
        price = "#{price} dkr."
      end
      service_response.text = t translation_key % "text", :price => price || nil
      service_response.note = t translation_key % "note", :doctype => reference.doctype, :price => price || nil
    end
    "data: #{service_response.to_json}\n\n"
  end
end