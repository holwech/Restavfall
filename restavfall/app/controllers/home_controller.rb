class HomeController < ApplicationController
    def time(name, &block) #For debug only
        t = Time.now
        result = block.call
        puts "#{name} completed in #{(Time.now - t)} seconds"
        result
    end

    @@host = "https://www.facebook.com/#{FACEBOOK_CONFIG["page_id"]}"+
             "?sk=app_#{FACEBOOK_CONFIG["app_id"]}";
    @@permissions = ['user_friends', 'user_photos', 'user_events'];

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
            me = graph.get_object('me?fields=id,name, first_name');
			picture = graph.get_picture("me", {:width => 100, :height => 100});
            session[:eventIDs] = UkeEvent.find_by_sql("SELECT DISTINCT ue.id 
                                                       FROM uke_event_data as ued, 
                                                            uke_events as ue, 
                                                            uke_showings as us
                                                       WHERE ue.title = ued.uke_event_title
                                                       AND ue.title = us.title
                                                       AND us.date > NOW()")
				.map{|e| e["id"]}
				.shuffle!
            session[:friend] = nil
            session[:event] = nil
            session[:user] = {:pic => picture, :fname => me['first_name'],
                              :id => me['id'], :name => me['name']};
            output = {"status": "OK", 
                      "next": "Posts", 
                      "text": "Analysing your posts"}
        when "Posts"
            #FriendFinder.analyse_posts(graph, session[:fs])
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

    def getEventByShowingId(id, friendName)
        events = UkeEvent.find_by_sql("SELECT *, ue.id as id
                              FROM uke_events as ue,
                                   uke_showings as us,
                                   uke_event_data as ued 
                              WHERE ue.id = #{id}
                              AND ue.title = us.title
                              AND ue.title = ued.uke_event_title
							  ORDER BY us.date
			      ")

		sel_event = nil
        events.each{|event|
            if event["date"] < Time.now
                next
            end
            if event["sold_out"] == 1
                next
            end
			sel_event = event
			break
        }
		if not sel_event
			sel_event = events.first
			sel_event["sold_out"] = 1
		end
		sel_event["description"].sub! "%navn%", friendName
        return sel_event
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
        @ev = getEventByShowingId(result.eventId, result.friendFName)

        @selfName = result.userName
        @selfImage = result.userImg
        @friendName = result.friendName
        @friendFName = result.friendFName
		@selfFName = result.userFName
        @friendImage = result.friendImg
        @redirecturl = @@host
    end

    def closFe
    end

    def getFriendAndEvent(graph)
        friend = FriendFinder.get_one_friend(graph, session[:fs])
		if friend
			session[:friend] = friend
		else
			session[:friend] = session[:user]
		end

        id = session[:eventIDs].first
        event = getEventByShowingId(id, session[:friend][:fname])
        session[:eventIDs].rotate!

        session[:event] = event
        session[:link] = saveResult
    end

    def saveResult
        res = Result.new
        res.userFName = session[:user][:fname]
        res.userName = session[:user][:name]
        res.userImg = session[:user][:pic]
        res.friendName = session[:friend][:name]
        res.friendFName = session[:friend][:fname]
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
