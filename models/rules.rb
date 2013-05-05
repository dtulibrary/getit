
require_relative "../helpers/rules_helper"
require_relative "../helpers/application_helper"

module Rules
  include RulesHelper
  include ApplicationHelper

  def add_fulltext_rules(user_type)

    # direct fulltext access (via local store or sfx) is preferred over order,
    # for public version this only applies to open access     
    subtype = ["public", "anonymous"].include?(user_type) ? "openaccess" : nil
    rule :direct_fulltext_preempts_scan,
         reply: service_is_not("scan"),
         skip: has_sent_services(subtype, ["metastore", "sfx"]),
         wait: has_not_processed_services(["metastore", "sfx"])

    fulltext_common_rules(user_type)
  end

  def add_fulltext_short_rules(user_type)    
    # only one response needed
    rule :max_one,
         priority: 1,
         skip: has_seen_any

    rule :openaccess_preempts_scan,
         priority: 2,
         reply: service_is_not("scan"),
         skip: has_sent_services("openaccess", ["metastore", "sfx"]),
         wait: has_not_processed_services(["metastore", "sfx"])

    if(dtu?(user_type))     

      # DTU - licensed higher priority than open access
      rule :license_preempts_openaccess,
            priority: 3,
            reply: service_and_subtype_is_not("openaccess", ["sfx", "metastore"]),
            skip: has_sent_services("license", ["metastore", "sfx"]),
            wait: has_not_processed_services(["metastore", "sfx"])
    else

      # Public: Scan higher priority than license
      rule :scan_preempts_licensed,
           priority: 3,
           reply: service_and_subtype_is_not("license", ["sfx", "metastore"]),
           skip: has_sent_services(["scan"]),
           wait: has_not_processed_services(["scan"])
    end

    fulltext_common_rules(user_type)
  end

  def fulltext_common_rules(user_type)

    # metastore responses are preferred over sfx responses for the same subtypes (licensed or open access)
    rule :metastore_preempts_sfx,   
         # only relevant for sfx responses 
         reply: service_is_not("sfx"),
         # response should be skipped if we have already seen one from metastore with the same subtype
         skip: has_sent_service_with_same_subtype("metastore"),
         # wait for decision if we haven't seen any responses from metastore yet
         wait: has_not_processed_services(["metastore"])
  end

end