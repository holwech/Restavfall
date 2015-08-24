class UkeeventController < ApplicationController
    def index
        @links = ""
        if params.has_key?("update")
            require 'open-uri'
            require 'json'
            require 'htmlentities'

            puts "Updating..."

            fb_events = open("https://www.facebook.com/pages/UKA/24216860753?sk=events").read
            fb_events = fb_events.force_encoding("utf-8")
            fb_events = HTMLEntities.new.decode(fb_events)
            links = fb_events.scan(/<a href="\/events\/([0-9]*)[^>]*>([^<]*)<\/a>/)
            links = links.map{|l| Hash[[:id, :text].zip(l)]}

            UkeFbEvent.destroy_all({:auto_generated => true})
            UkeEvent.destroy_all()
            UkeShowing.destroy_all()
            result = JSON.parse(open("https://www.uka.no/program/?format=json").read)
            result.each{|event|
                links.each{|l|
                    if l[:text].include? event["title"]
                        l[:event] = event["title"]
                        json = {"uke_event_id": event["id"],
                                "fb_event_id": l[:id],
                                "auto_generated": true}
                        UkeFbEvent.new(json).save()
                    end
                }
                showings = event.delete("showings")
                UkeEvent.new(event).save()
                showings.each{|showing|
                    showing["uke_event_id"] = event["id"]
                    UkeShowing.new(showing).save()
                }
            }

        end

        @events = UkeEvent.find_by_sql("SELECT E.id, E.title, S.place, S.date, S.id as showing_id, E.image, S.url, F.fb_event_id FROM uke_showings AS S, uke_events AS E LEFT OUTER JOIN uke_fb_events AS F ON E.id = F.uke_event_id WHERE S.uke_event_id = E.id");
    end

    def fb_events
        @events = UkeEvent.find_by_sql("SELECT ufe.auto_generated, ue.id, ue.title, ufe.fb_event_id FROM uke_events as ue LEFT JOIN uke_fb_events as ufe ON ue.id = ufe.uke_event_id")
        @events.each{|e|
            puts e.to_json
        }
    end

    def save_fb_event
        id = params["id"]

        if params["edit"]
            UkeFbEvent.destroy_all({:uke_event_id => id})
        end

        if not params["fb_event_id"] == ""
            UkeFbEvent.new({:uke_event_id => id,
                            :fb_event_id => params["fb_event_id"],
                            :auto_generated => false}).save()
        end

        render :nothing => true, :status => 200
    end
end
