class HomeController < ApplicationController
    def time(name, &block) #For debug only
        t = Time.now
        result = block.call
        puts "#{name} completed in #{(Time.now - t)} seconds"
        result
    end

    def return_host
        if Rails.env.production?
            request.host
        else
            "#{request.host}:#{request.port}"
        end
    end

    def redirect
        reset_session

        oauth =   Koala::Facebook::OAuth.new(FACEBOOK_CONFIG["app_id"], FACEBOOK_CONFIG["secret"], 
		  "https://#{return_host}/auth/facebook/callback")
        redirect_to oauth.url_for_oauth_code(:permissions => 
                                             ['user_friends', 'user_photos', 'user_events',
                                              'read_stream', 'publish_actions'])
    end

    def login
        time("login") {
            oauth =   Koala::Facebook::OAuth.new(FACEBOOK_CONFIG["app_id"], FACEBOOK_CONFIG["secret"], 
		  "https://#{return_host}/auth/facebook/callback")
            session[:token] = oauth.get_access_token(params[:code])
        }
        redirect_to '/index' and return
    end

    def index
        if not session.has_key?('token')
            puts "ERROR"
            return
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
