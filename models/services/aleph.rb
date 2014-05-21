# -*- encoding : utf-8 -*-

class Aleph
  include Service

  MONTH_ABBR_MAP = {"maj" => "may", "okt" => "oct"}.freeze
  LENDING_STATUS = {
    "Not received" => :unavailable,
    "Rykket" => :unavailable,
    "Ikke udkommet" => :unavailable,
    "Til indbinding" => :unavailable,
    "Bortkommet" => :unavailable,
    "Missing p.t." => :unavailable,
    "Missing/bill" => :unavailable,
    "Discarded" => :unavailable,
    "Acquisition" => :unavailable,
    "Binder" => :unavailable,
    "Bortkommet" => :unavailable,
    "Restoration" => :unavailable,
    "In bindery" => :unavailable,
    "non-copy-circ" => :unavailable,
    "Elec. ed." => :unavailable,
    "Back order" => :unavailable,
    "Claimed" => :unavailable,
    "Not published" => :unavailable,
    "Out of print" => :unavailable,
    "Reject" => :unavailable,
    "Lost" => :unavailable,
    "Reading Room" => :available_onsite,
    "Not for loan" => :available_onsite,
    "On exhibition" => :available_onsite,
    "New book displ" => :available_onsite,
    "ReadingRoom DTV" => :available_onsite
  }

  def parse_response(response)

    service_responses = []

    doc = Nokogiri::XML(response[:body])
    item_list = doc.search('/zs:searchRetrieveResponse/zs:records/zs:record/zs:recordData/record/item')

    if item_list.size > 0

      loan_response = LoanServiceResponse.new
      item_list.each do |item|

        status = LoanServiceResponse::Status.new

        location = ""
        sub_division = ""
        lending_period = ""

        item.children.each do |child|
          case child.name
          when "available"
            case child.content
            when "Udlånt"
              status.availability = :unavailable
            when "På ventehylde"
              status.availability = :unavailable
            when "På hylden"
              status.availability = :available
            when /Reserveret/
              # Format: ex. '21/mar/2014 Reserveret'
              # it is out on loan and has been reserved by another user
              status.availability = :unavailable
            when "I bestilling"
              status.availability = :unavailable
            when "Tabt/Regning"
              status.availability = :unavailable
            else
              if LENDING_STATUS.include?(child.content)
                status.availability = LENDING_STATUS[child.content]
              else
                Kyandi.logger.error "Aleph service: Unknown status #{child.content} for alis id #{@reference.custom_co_data["alis_id"]}"
              end
            end
          when "due"
            due_date = child.content
            if m = /\d*\/(\w*)\/\d{4}/.match(due_date)
              if MONTH_ABBR_MAP.has_key?(m[1])
                due_date.sub!(m[1], MONTH_ABBR_MAP[m[1]])
              end
            end
            begin
              status.due_date = Date.parse(due_date).to_datetime
            rescue ArgumentError
            end
          when "collection"
            location = child.content
            if location.include?("Ballerup")
              location = "DTU Ballerup"
            else
              location = "DTU Lyngby"
            end
          when "placement"
            sub_division = child.content
          when "callno"
            status.callno = child.content
          when "lendingPeriod"
            lending_period = child.content
          end
        end

        if LENDING_STATUS.include?(lending_period)
          status.availability = LENDING_STATUS[lending_period]
        end

        if ["Textbook collection", "Reference collection", "Closed stacks"].include?(sub_division)
          status.availability = :available_onsite
          if sub_division == "Closed stacks"
            status.callno = ""
          end
        end

        url = "#{@configuration['aleph_url']}#{@reference.custom_co_data["alis_id"]}"
        if status.availability == :available_onsite
          status.text = I18n.t("loan.availability.#{status.availability}.text", :url => url)
        else
          status.text = I18n.t("loan.availability.#{status.availability}.text")
          status.url = url
          status.url_text = I18n.t("loan.availability.#{status.availability}.url_text")
        end
        status.text_long = I18n.t("loan.availability.#{status.availability}.text_long") unless status.availability == :unavailable
        status.icon = I18n.t("loan.availability.#{status.availability}.icon")
        status.icon_color = I18n.t("loan.availability.#{status.availability}.icon_color")
        if status.availability == :unavailable && !status.due_date.nil?
          set_text_with_date(status)
        end

        # set summary to current status if it is the most optimistic status we have seen so far
        if LoanServiceResponse::Status.availabilities[loan_response.summary.availability] < LoanServiceResponse::Status.availabilities[status.availability]
          loan_response.summary = status
        end

        if loan_response.locations.has_key?(location)
          # merge identical statuses
          existing_status = loan_response.locations[location].find do |s|
            s.availability == status.availability && s.callno == status.callno
          end
          if existing_status.nil?
            loan_response.locations[location] << status
          else
            existing_status.count += 1
            if (!status.due_date.nil? && existing_status.due_date.nil?) || (!status.due_date.nil? && !existing_status.due_date.nil? && (status.due_date < existing_status.due_date))
              existing_status.due_date = status.due_date
              set_text_with_date(existing_status)
            end
          end
        else
          loan_response.locations[location] = [status]
        end
      end

      service_responses << loan_response
    end

    service_responses
  end

  def set_text_with_date(status)
    status.text = I18n.t('loan.availability.unavailable.text_with_until', :due => status.due_date.strftime('%-d/%-m-%Y'))
    status.text_long = I18n.t('loan.availability.unavailable.text_with_until_long', :due => status.due_date.strftime('%-d/%-m-%Y'))
  end

  def get_query
    {
      "version" => "1.1",
      "operation" => "searchRetrieve",
      "query" => "rec.id=#{@reference.custom_co_data["alis_id"]}",
      "maximumRecords" => "1",
      "x-username" => @configuration['username'],
      "x-password" => @configuration['password']
    }
  end

end
