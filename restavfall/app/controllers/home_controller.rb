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
        reset_session

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
                session[:token] = req["oauth_token"]
                redirect_to(	:controller => 'home', 
				:action => 'index', 
				:signed_request => params[:signed_request] )  and return
            end
        end

        @url = oauth.url_for_oauth_code(:permissions => @@permissions)
    end

    def index
        if not session.has_key?('token')
            puts "Missing token"
            redirect_to '/' and return
        end

        graph = Koala::Facebook::API.new(session[:token])
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

        @user = session[:user]
        @event = session[:event]
        @friend = session[:friend]
        @link = session[:link]
        @sr = params[:signed_request]
    end

    def analyse
        stage = params[:stage]

        if stage == "Start"
            session[:fs] = {}
		elsif stage == "Token"
			session[:token] = params[:token]
			puts "Got token: " + session[:token]
            output = {"status": "OK"}
			render json: output
			return
        end

        graph = Koala::Facebook::API.new(session[:token])
        session[:fs].default_proc = proc{ |hash, key| hash[key] = 0 }

        case stage
        when "Start"
            me = graph.get_object('me?fields=id,name');
			picture = graph.get_picture("me", {:width => 100, :height => 100});
            session[:eventIDs] = UkeEvent.find_by_sql("SELECT ue.id FROM uke_event_data as ued, uke_events as ue WHERE ue.title = ued.uke_event_title")
				.map{|e| e["id"]}
				.shuffle!
            session[:friend] = nil
            session[:event] = nil
            session[:user] = {:pic => picture, 
                              :id => me['id'], :name => me['name']};
            output = {"status": "OK", 
                      "next": "Posts", 
                      "text": "Analysing your posts"}
        when "Posts"
            FriendFinder.analyse_posts(graph, session[:fs])
            output = {"status": "OK", "next": "Photos"}
        when "Photos"
            FriendFinder.analyse_photos(graph, session[:fs])
            output = {"status": "OK", "next": "Events"}
        when "Events"
            FriendFinder.analyse_events(graph, session[:fs])
            output = {"status": "OK", "next": "Friends"}
        when "Friends"
            FriendFinder.make_friend_data(graph, 
                                                        session[:fs], 
                                                        session[:user][:id])
            output = {"status": "OK", "next": "FriendEvent"}
        when "FriendEvent"
            getFriendAndEvent(graph)
            output = {"status": "Done",  
                      "user": session[:user], 
                      "friend": session[:friend], 
                      "event": session[:event], 
                      "link": session[:link]}
        else
            output = {"status": "Error"}
        end

		# Truncate to top 100 friends
		if session[:fs].length > 100
			short_list = session[:fs].
                                sort_by{|id, value|  value}.
                                reverse.
                                first(100)
			session[:fs].clear
			short_list.each{|f|
				session[:fs][f[0]] = f[1]
			}	
		end

        session[:fs].default_proc = nil
        render json: output
    end

    def getEventByShowingId(id)
        event = UkeEvent.find_by_sql("SELECT *
                              FROM uke_events as ue 
                              WHERE ue.id = #{id}
			      ").first

        sql = "SELECT *, ue.id as id
               FROM uke_events as ue, uke_showings as us, uke_event_data as ued
               WHERE ue.title = us.title
               AND ue.id = #{id}
               AND ue.title = ued.uke_event_title"

        if not event.done
            sql += " AND us.date > NOW()"
        end

        if not event.sold_out
            sql += " AND us.sold_out = false"
        end

        sql += " ORDER BY us.date"

        puts "Executing sql: #{sql}"
        event = UkeEvent.find_by_sql(sql).first
        puts event.to_json
        return event
    end

    def uno
        @r = !params[:redir].nil?
        @rid = params[:rid]
		@sr = params[:signed_request]
        @token = ""
        oauth = Koala::Facebook::OAuth.new(
            FACEBOOK_CONFIG["app_id"], 
            FACEBOOK_CONFIG["secret"], 
            @@host)
		req = oauth.parse_signed_request(params[:signed_request])
		if req.has_key?("oauth_token")
			@token = req["oauth_token"];
			session[:token] = @token
		end
		if @token != ""
			graph = Koala::Facebook::API.new(@token)
			granted_permissions = graph.get_connections('me','permissions')
			.delete_if{|p| p["status"] != "granted"}
			.map{|p| p["permission"]}

			missing_permissions = @@permissions - granted_permissions;

			if missing_permissions.length > 0
				@token = ""
			end
		end

        result = Result.find(@rid)
        @ev = getEventByShowingId(result.eventId)

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
        friend = FriendFinder.get_one_friend(graph, session[:fs])
        id = session[:eventIDs].first
        event = getEventByShowingId(id)
        session[:eventIDs].rotate!

		if friend
			session[:friend] = friend
		else
			session[:friend] = session[:user]
		end
        session[:event] = event
        session[:link] = saveResult
    end

    def saveResult
        res = Result.new
        res.userName = session[:user][:name]
        res.userImg = session[:user][:pic]
        res.friendName = session[:friend][:name]
        res.friendImg = session[:friend][:pic]
        res.eventId = session[:event]["id"]
        res.save!
        return res.id
    end

	def policy
	end
	def test
	end
end
