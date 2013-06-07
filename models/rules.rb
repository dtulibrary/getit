require_relative "../helpers/rules_helper"
require_relative "../helpers/application_helper"

# Rule format:
#
# rule :name,
#      priority: number 
#      reply: [conditions] (msg send ok if conditions => true)
#      skip:  [conditions] (msg send not ok if conditions => true)
#      wait:  [conditions] (hold msg if conditions => true) 
#
module Rules
  include RulesHelper
  include ApplicationHelper

  def add_fulltext_rules

    # DTU - direct fulltext access is preferred over scan
    rule :direct_fulltext_preempts_scan,
         reply: [user_is_not_dtu, service_is_not("scan")],
         skip: has_seen_services(["metastore", "sfx"]),
         wait: has_not_seen_services(["metastore", "sfx"])

    # Public - scan is preferred over licensed direct fulltexts
    rule :openaccess_fulltext_preempts_scan,
         reply: [user_is_dtu, service_is_not("scan")],
         skip: has_seen_services("openaccess", ["metastore", "sfx"]),
         wait: has_not_seen_services(["metastore", "sfx"])

    fulltext_common_rules
  end

  def add_fulltext_short_rules

    # only one response needed
    rule :max_one,
         priority: 1,
         skip: has_sent_any

    rule :openaccess_preempts_scan,
         priority: 2,
         reply: [service_is_not("scan")],
         skip: has_seen_services("openaccess", ["metastore", "sfx"]),
         wait: has_not_seen_services(["metastore", "sfx"])

    # DTU - licensed higher priority than open access
    rule :license_preempts_openaccess,
          priority: 3,
          reply: [user_is_not_dtu, service_and_subtype_is_not("openaccess", ["sfx", "metastore"])],
          skip: has_seen_services("license", ["metastore", "sfx"]),
          wait: has_not_seen_services(["metastore", "sfx"])

    # Public - Scan higher priority than license
    rule :scan_preempts_licensed,
         priority: 3,
         reply: [user_is_dtu, service_and_subtype_is_not("license", ["sfx", "metastore"])],
         skip: has_seen_services(["scan"]),
         wait: has_not_seen_services(["scan"])

    fulltext_common_rules
  end

  def fulltext_common_rules

    # metastore has higher priority than sfx for the same subtypes (licensed or open access)
    rule :metastore_preempts_sfx,   
         reply: service_is_not("sfx"),
         skip: has_seen_service_with_same_subtype("metastore"),
         # wait for decision if we haven't seen any responses from metastore yet
         wait: has_not_seen_services(["metastore"])
  end

end