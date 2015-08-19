class HomeController < ApplicationController
    def time(name, &block) #For debug only
        t = Time.now
        result = block.call
        puts "#{name} completed in #{(Time.now - t)} seconds"
        result
    end

    def return_host
	    if Rails.env.production?
		    if session.has_key?("page_id")
			"https://www.facebook.com/#{session["page_id"]}?sk=app_#{FACEBOOK_CONFIG["app_id"]}"	
		    else
			    "https://apps.facebook.com/prosjektrestavfall"
		    end
	    else
		    "https://#{request.host}:#{request.port}"
	    end
    end

    @@permissions = ['user_friends', 'user_photos', 'user_events', 'read_stream'];

    def redirect
        reset_session
        oauth =   Koala::Facebook::OAuth.new(FACEBOOK_CONFIG["app_id"], 
					     FACEBOOK_CONFIG["secret"])

	if params.has_key?("signed_request")
		req = oauth.parse_signed_request(params[:signed_request])
		Rails.logger.info req

		# If app is on tab page
		if req.has_key?("page")
			session[:page_id] = req["page"]["id"]
		end

		# If user is already authenticated
		if req.has_key?("oauth_token")
			session[:token] = req["oauth_token"]
			redirect_to '/index' and return
		end
	end

	# Create oauth with return url
	oauth =   Koala::Facebook::OAuth.new(FACEBOOK_CONFIG["app_id"], 
			FACEBOOK_CONFIG["secret"], 
			return_host)
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
                return_host)
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
    end

    def analyse
        stage = params[:stage]

        if stage == "Start"
            session[:fs] = {}
        end

        graph = Koala::Facebook::API.new(session[:token])
        session[:fs].default_proc = proc{ |hash, key| hash[key] = 0 }

        case stage
        when "Start"
            me = graph.get_object('me?fields=id,name,picture');
            session[:eventIDs] = Event.pluck(:id).shuffle!
            session[:friend] = nil
            session[:event] = nil
            session[:user] = {:pic => me['picture']['data']['url'], 
                              :id => me['id'], :name => me['name']};
            output = {"status": "OK", 
                      "next": "Posts", 
                      "text": "Analysing your posts"}
        when "Posts"
            FriendFinder.analyse_posts(graph, session[:fs])
            output = {"status": "OK", "next": "Photos", "text": "Analysing your photos"}
        when "Photos"
            FriendFinder.analyse_photos(graph, session[:fs])
            output = {"status": "OK", "next": "Events", "text": "Analysing your events"}
        when "Events"
            FriendFinder.analyse_events(graph, session[:fs])
            output = {"status": "OK", "next": "Friends", "text": "Gathering the candidates"}
        when "Friends"
            friend_data = FriendFinder.make_friend_data(graph, 
                                                        session[:fs], 
                                                        session[:user][:id])
            output = {"status": "OK", "next": "FriendEvent", "friends": friend_data,
                      "text": "Finding your ideal UKE-friend!"}
            session[:fd] = friend_data
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

        session[:fs].default_proc = nil
        render json: output
    end

    def uno
        @r = !params[:redir].nil?
        @rid = params[:rid]

        result = Result.find(@rid)
        @ev = Event.find(result.eventId)

        @selfName = result.userName
        @selfImage = result.userImg
        @friendName = result.friendName
        @friendImage = result.friendImg
        @eventtime = @ev['time'].strftime('%d. %B');
    end

    def close
    end

    def getFriendAndEvent(graph)
        friend = FriendFinder.get_one_friend(graph, session[:fd])

        event = Event.find(session[:eventIDs].first)
        event['img'] = ActionController::Base.helpers.asset_path(event['img']);
        session[:eventIDs].rotate!

        session[:friend] = friend
        session[:event] = event
        session[:link] = saveResult
    end

    def saveResult
        res = Result.new
        res.userName = session[:user][:name]
        res.userImg = session[:user][:pic]
        res.friendName = session[:friend]['name']
        res.friendImg = session[:friend]['pic']
        res.eventId = session[:event][:id]
        res.save!
        return res.id
    end
end
