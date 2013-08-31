require 'json'
require 'openurl'

class Reference

  attr_reader :context_object

  def initialize(params)
    # remove sse param
    params.delete("r")
    # create context object from parameters
    # note that no validity check on openurl parameters are made     
    @context_object = OpenURL::ContextObject.new_from_form_vars(params)
  end

  def service_list_name
    @context_object.serviceType.first.private_data if @context_object.serviceType.length > 0
  end

  def clean_context_object
    if !defined?(@clean_context_object)
      @clean_context_object = OpenURL::ContextObject.new_from_kev(@context_object.kev)
      @clean_context_object.requestor.identifiers.each {|id| clean_context_object.requestor.delete_identifier(id)}        
      @clean_context_object.serviceType.first.set_private_data('') if clean_context_object.serviceType.length > 0
    end
    @clean_context_object
  end

  def custom_co_data
    data = {}
    if @context_object.referent.metadata.has_key?('data')
      data = JSON.parse(@context_object.referent.metadata['data']) 
    end
    data
  end

  def doctype
    doctype = @context_object.referent.metadata["genre"]
    doctype ||= @context_object.referent.format
  end

  def user_type
    type = @context_object.requestor.identifiers.first || "public"
    type = "public" if type == "anonymous"  
    type
  end

  def dtu?
    ["dtu_staff", "dtu_student", "walkin"].include?(user_type)
  end
end