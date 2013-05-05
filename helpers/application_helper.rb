
module ApplicationHelper  
  
  def title(value = nil)
    @title = value if value
    @title ? "GetIt - #{@title}" : "GetIt" 
  end

  def get_class(class_name)    
    begin
      klass = Module.const_get(class_name)
      return klass.is_a?(Class) ? klass : nil
    rescue NameError      
      nil
    end    
  end

  def write_response(service_response, user_type, context_object, prices)
    translation_key = "#{service_response.service_type}.#{service_response.subtype}.text"
    translation_key << ".#{user_type}" if service_response.subtype.eql?("license")
    if(service_response.source.eql?("scan"))
      price = prices[service_response.subtype][user_type] || -1
      price = "No" if price == 0
      price = "#{price} dkr."
    end
    service_response.text = t translation_key, :price => price || nil
    service_response.note = t translation_key, :doctype => doctype(context_object), :price => price || nil
    "data: #{service_response.to_json}\n\n"
  end

  def get_user_type(context_object)    
    context_object.requestor.identifiers.first || "anonymous"
  end

  def t(*args)
    I18n.t(*args)
  end

  def doctype(context_object)
    doctype = context_object.referent.format
    if(doctype == "journal")
      # could be both an article or a journal
      #TODO make sure genre is set
      if(context_object.referent.metadata.has_key?("genre"))
        doctype = context_object.referent.metadata["genre"]
      end
    end
    return doctype
  end

  def dtu?(user_type)
    ["dtu_staff", "dtu_student", "walkin"].include?(user_type)
  end

end