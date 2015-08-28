class HomeController < ApplicationController
    def time(name, &block) #For debug only
        t = Time.now
        result = block.call
        puts "#{name} completed in #{(Time.now - t)} seconds"
        result
    end

    @@host = "https://www.facebook.com/#{FACEBOOK_CONFIG["page_id"]}"+
             "?sk=app_#{FACEBOOK_CONFIG["app_id"]}";
    @@permissions = ['user_friends', 'user_photos', 'user_events', 'read_stream'];

    def redirect
		Rails.cache.delete("session");

        # Create oauth with return url
        oauth = Koala::Facebook::OAuth.new(
            FACEBOOK_CONFIG["app_id"], 
            FACEBOOK_CONFIG["secret"], 
            @@host)

        if params.has_key?("signed_request")
            req = oauth.parse_signed_request(params[:signed_request])

            # If app data is set, redirect to uno
            if req.has_key?("app_data") and not params.has_key?("stop")
                redirect_to(	:controller => 'home', 
				:action => 'uno', 
				:rid => req["app_data"],
				:signed_request => params[:signed_request] )  and return
            end

            # If user is already authenticated
            if req.has_key?("oauth_token")
				Rails.cache.write("session", {:token => req["oauth_token"]})
                redirect_to(	:controller => 'home', 
				:action => 'index', 
				:signed_request => params[:signed_request] )  and return
            end
        end

        @url = oauth.url_for_oauth_code(:permissions => @@permissions)
    end

    def index
		sess = Rails.cache.fetch("session")
        graph = Koala::Facebook::API.new(sess[:token])
        granted_permissions = graph.get_connections('me','permissions')
        .delete_if{|p| p["status"] != "granted"}
        .map{|p| p["permission"]}

        missing_permissions = @@permissions - granted_permissions;

        if missing_permissions.length > 0
            oauth =   Koala::Facebook::OAuth.new(
                FACEBOOK_CONFIG["app_id"], FACEBOOK_CONFIG["secret"], 
                @@host)
            @url = oauth.url_for_oauth_code(
                :auth_type => "rerequest",
                :permissions => @@permissions)
            @missing = missing_permissions
            render 'missing_permissions' and return
        end

        @user = sess[:user]
        @event = sess[:event]
        @friend = sess[:friend]
        @link = sess[:link]
        @sr = params[:signed_request]
    end

    def analyse
        stage = params[:stage]
		sess = Rails.cache.fetch("session")

        if stage == "Start"
            sess[:fs] = {}
        end

        graph = Koala::Facebook::API.new(sess[:token])
        sess[:fs].default_proc = proc{ |hash, key| hash[key] = 0 }

        case stage
        when "Start"
            me = graph.get_object('me?fields=id,name,picture');
            sess[:eventIDs] = UkeShowing.find_by_sql("SELECT id FROM uke_showings")
				.map{|e| e["id"]}
				.shuffle!
            sess[:friend] = nil
            sess[:event] = nil
            sess[:user] = {:pic => me['picture']['data']['url'], 
                              :id => me['id'], :name => me['name']};
            output = {"status": "OK", 
                      "next": "Posts", 
                      "text": "Analysing your posts"}
        when "Posts"
            FriendFinder.analyse_posts(graph, sess[:fs])
            output = {"status": "OK", "next": "Photos", "text": "Analysing your photos"}
        when "Photos"
            FriendFinder.analyse_photos(graph, sess[:fs])
            output = {"status": "OK", "next": "Events", "text": "Analysing your events"}
        when "Events"
            FriendFinder.analyse_events(graph, sess[:fs])
            output = {"status": "OK", "next": "Friends", "text": "Gathering the candidates"}
        when "Friends"
            friend_data = FriendFinder.make_friend_data(graph, 
                                                        sess[:fs], 
                                                        sess[:user][:id])
            output = {"status": "OK", "next": "FriendEvent", "friends": friend_data,
                      "text": "Finding your ideal UKE-friend!"}
            sess[:fd] = friend_data
        when "FriendEvent"
            getFriendAndEvent(graph)
            output = {"status": "Done",  
                      "user": sess[:user], 
                      "friend": sess[:friend], 
                      "event": sess[:event], 
                      "link": sess[:link]}
        else
            output = {"status": "Error"}
        end

        sess[:fs].default_proc = nil

		Rails.cache.write("session", sess)

        render json: output
    end

    def getEventByShowingId(id)
        UkeEvent.find_by_sql("SELECT * , us.id as id
                              FROM uke_showings as us, uke_events as ue 
                              LEFT OUTER JOIN uke_event_data as ued 
                              ON ued.uke_event_id = ue.id
                              WHERE us.id = #{id} AND us.uke_event_id = ue.id 
			      ").first
    end

    def uno
        @r = !params[:redir].nil?
        @rid = params[:rid]
        @sr = params[:signed_request]

        result = Result.find(@rid)
        @ev = getEventByShowingId(result.eventId)
        puts "Event"
        puts @ev.to_json

        @selfName = result.userName
        @selfImage = result.userImg
        @friendName = result.friendName
        @friendImage = result.friendImg
        @eventtime = l(@ev['date'], format: '%e. %B');
        @redirecturl = @@host
    end

    def close
    end

    def getFriendAndEvent(graph)
		sess = Rails.cache.fetch("session")
        friend = FriendFinder.get_one_friend(graph, sess[:fd])
        id = sess[:eventIDs].first
        event = getEventByShowingId(id)
        sess[:eventIDs].rotate!

        sess[:friend] = friend
        sess[:event] = event
        sess[:link] = saveResult
		Rails.cache.write("session", sess);
    end

    def saveResult
		sess = Rails.cache.fetch("session")
        res = Result.new
        res.userName = sess[:user][:name]
        res.userImg = sess[:user][:pic]
        res.friendName = sess[:friend]['name']
        res.friendImg = sess[:friend]['pic']
        res.eventId = sess[:event]["id"]
        res.save!
		Rails.cache.write("session", sess);
        return res.id
    end
end
