# -*- encoding : utf-8 -*-

class Aleph
  include Service

  MONTH_ABBR_MAP = {"maj" => "may", "okt" => "oct"}.freeze

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
        due_date = nil

        item.children.each do |child|
          case child.name
          when "available"
            case child.content
            when "Udlånt"
              status.availability = :unavailable
            when "På hylden"
              status.availability = :available
            when /Reserveret/
              # Format: ex. '21/mar/2014 Reserveret'
              # it is out on loan and has been reserved by another user
              status.availability = :unavailable
            when "I bestilling"
              status.availability =:unavailable
            else
              Kyandi.logger.error "Aleph service: Unknown status #{child.content} for alis id #{@reference.custom_co_data["alis_id"]}"
            end
          when "due"
            due_date = child.content
            if m = /\d*\/(\w*)\/\d{4}/.match(due_date)
              if MONTH_ABBR_MAP.has_key?(m[1])
                due_date.sub!(m[1], MONTH_ABBR_MAP[m[1]])
              end
            end
            begin
              due_date = Date.parse(due_date).to_datetime.strftime('%-d/%-m-%Y')
            rescue ArgumentError
            end
          when "location"
            if m = /(.*) \/ (.*)/.match(child.content)
              location = m[1]
              if location.include?("Ballerup")
                location = "DTU Ballerup"
              else
                location = "DTU Lyngby"
              end
              sub_division = m[2]
            end
          when "callno"
            status.callno = child.content
          end
        end

        if ["Textbook collection", "Reference collection"].include?(sub_division)
          status.availability = :available_onsite
        end

        status.text = I18n.t("loan.availability.#{status.availability}.text")
        status.text_long = I18n.t("loan.availability.#{status.availability}.text_long") if status.availability == :available
        status.icon = I18n.t("loan.availability.#{status.availability}.icon")
        status.icon_color = I18n.t("loan.availability.#{status.availability}.icon_color")
        unless status.availability == :available_onsite
          status.url_text = I18n.t("loan.availability.#{status.availability}.url_text")
          status.url = "#{@configuration['aleph_url']}#{@reference.custom_co_data["alis_id"]}"
        end
        if status.availability == :unavailable && !due_date.nil?
          status.text = I18n.t('loan.availability.unavailable.text_with_until', :due => due_date)
          status.text_long = I18n.t('loan.availability.unavailable.text_with_until_long', :due => due_date)
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
          end
        else
          loan_response.locations[location] = [status]
        end
      end

      service_responses << loan_response
    end

    service_responses
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
