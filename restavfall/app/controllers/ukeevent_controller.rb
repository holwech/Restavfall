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
            event_titles = []
            proper_results = {}

            UkeEvent.destroy_all({:auto_generated => true})
            UkeShowing.destroy_all({:auto_generated => true})
            result = JSON.parse(open("https://www.uka.no/program/?format=json").read)
            result.each{|event|
                if excluded_categories.include? event["event_type"]
                    next
                end
                showings = event.delete("showings");
                if not event_titles.include? event["title"]
                    proper_results[event["title"]] = event;
                    proper_results[event["title"]]["showings"] = [];
                    event_titles << event["title"]
                end
                showings.each{|showing|
                    proper_results[event["title"]]["showings"] << showing;
                }
            }

            proper_results.each{|title, event|
                sold_out = true
                done = true
                event["showings"].each{|showing|
                    if Date.parse(showing["date"]) > Date.today
                        done = false
                    end
                    if showing["status"] != "Utsolgt"
                        sold_out = false
                    end
                }
                UkeEvent.new({
                            :id => event["id"],
                            :title => event["title"],
                            :image => event["image"],
                            :sold_out => sold_out,
                            :done => done,
                            :auto_generated => true}).save()
                event["showings"].each{|showing|
                    UkeShowing.new({
                        :title => showing["title"],
                        :sold_out => showing["status"] == "Utsolgt",
                        :date => showing["date"],
                        :url => showing["url"],
                        :place => showing["place"],
                        :auto_generated => true}      ).save()
                }
            }

        end

        @events = UkeEvent.find_by_sql("SELECT *, E.id as id FROM uke_showings AS S, uke_events AS E LEFT OUTER JOIN uke_event_data AS F ON E.title = F.uke_event_title WHERE S.title = E.title");
    end

    def event_data
        @events = UkeEvent.find_by_sql("SELECT ue.title, ufe.description FROM uke_events as ue LEFT JOIN uke_event_data as ufe ON ue.title = ufe.uke_event_title ORDER BY ue.title")
        @events.each{|e|
            puts e.to_json
        }
    end

    def save_data
		title = params["title"]
		UkeEventData.destroy_all({:uke_event_title => title})

        if not params["description"] == ""
            UkeEventData.new({:uke_event_title => title,
                            :description => params["description"]}).save()
        end

        render :nothing => true, :status => 200
    end
end
