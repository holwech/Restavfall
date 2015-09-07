class UkeeventController < ApplicationController
    before_filter :authenticate

    def authenticate
        authenticate_or_request_with_http_basic do |username, password|
            username == "admin" and password = "restavfall2015"
        end
    end

    def index
        @links = ""
        if params.has_key?("update")
            require 'open-uri'
            require 'json'

            puts "Updating..."

            excluded_categories = ["Dagens bedrift", "Inngang på huset"]

            UkeEvent.destroy_all()
            UkeShowing.destroy_all()
            result = JSON.parse(open("https://www.uka.no/program/?format=json").read)
            result.each{|event|
                if excluded_categories.include? event["event_type"]
                    next
                end
                showings = event.delete("showings")
                UkeEvent.new(event).save()
                showings.each{|showing|
                    showing["uke_event_id"] = event["id"]
                    UkeShowing.new(showing).save()
                }
            }

        end

        @events = UkeEvent.find_by_sql("SELECT * FROM uke_showings AS S, uke_events AS E LEFT OUTER JOIN uke_event_data AS F ON E.title = F.uke_event_title WHERE S.uke_event_id = E.id");
    end

    def event_data
        @events = UkeEvent.find_by_sql("SELECT DISTINCT ue.title, ufe.description FROM uke_events as ue LEFT JOIN uke_event_data as ufe ON ue.title = ufe.uke_event_title ORDER BY ue.title")
        @events.each{|e|
            puts e.to_json
        }
    end

    def save_data
        if not params["description"] == ""
            title = params["title"]

            UkeEventData.destroy_all({:uke_event_title => title})

            UkeEventData.new({:uke_event_title => title,
                            :description => params["description"]}).save()
        end

        render :nothing => true, :status => 200
    end
end
