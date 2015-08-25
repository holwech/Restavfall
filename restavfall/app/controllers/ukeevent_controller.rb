class UkeeventController < ApplicationController
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

        @events = UkeEvent.find_by_sql("SELECT * FROM uke_showings AS S, uke_events AS E LEFT OUTER JOIN uke_event_data AS F ON E.id = F.uke_event_id WHERE S.uke_event_id = E.id");
    end

    def event_data
        @events = UkeEvent.find_by_sql("SELECT ue.id, ue.title, ufe.description FROM uke_events as ue LEFT JOIN uke_event_data as ufe ON ue.id = ufe.uke_event_id ORDER BY ue.id")
        @events.each{|e|
            puts e.to_json
        }
    end

    def save_data
        if not params["description"] == ""
            id = params["id"]

            UkeEventData.destroy_all({:uke_event_id => id})

            UkeEventData.new({:uke_event_id => id,
                            :description => params["description"]}).save()
        end

        render :nothing => true, :status => 200
    end
end
