class HomeController < ApplicationController
    def redirect
        if session.has_key?('token')
            redirect_to '/index' and return
        end
        oauth =   Koala::Facebook::OAuth.new(FACEBOOK_CONFIG["app_id"], FACEBOOK_CONFIG["secret"], "https://#{request.host}:#{request.port}/auth/facebook/callback")
        redirect_to oauth.url_for_oauth_code(:permissions => 
                                             ['user_friends', 'user_photos', 'user_events',
                                              'read_stream', 'publish_actions'])
    end

    def login
        if not session.has_key?('token')
            auth = request.env["omniauth.auth"]
            session[:token] = auth['credentials']['token']
            graph = Koala::Facebook::API.new(session[:token])
            me = graph.get_object('me');
            me_pic = graph.get_picture('me');
            session[:user] = {:pic => me_pic, :id => me['id'], :name => me['name']};
        end
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
            output = {"status": "OK", "next": "Posts", "text": "Analysing your posts"}
            session[:friend] = nil
            session[:event] = nil
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
            friend_data = FriendFinder.make_friend_data(graph, session[:fs])
            output = {"status": "OK", "next": "FriendEvent", "friends": friend_data,
                      "text": "Finding your ideal UKE-friend!"}
            session[:fd] = friend_data
        when "FriendEvent"
            session[:eventIDs] = Event.pluck(:id).shuffle!
            event = Event.find(session[:eventIDs].first)
            session[:eventIDs].rotate!
            session[:event] = event

            friend = FriendFinder.get_one_friend(graph, session[:fd])
            session[:friend] = friend
            output = {"status": "Done",  "friend": friend, "event": event}
        when "Friend"
            friend = FriendFinder.get_one_friend(graph, session[:fd])
            session[:friend] = friend
            output = {"status": "Done", "friend": friend}
        when "Event"
            event = Event.find(session[:eventIDs].first)
            session[:eventIDs].rotate!
            session[:event] = event
            output = {"status": "Done", "event": event}
        else
            output = {"status": "Error"}
        end

        session[:fs].default_proc = nil
        render json: output
    end

    def uno
        uself = params[:uself]
        ufriend = params[:ufriend]
        @ev = Event.find(params[:ev])

        graph = Koala::Facebook::API.new(session[:token])
        @selfprofile = graph.get_object(uself)
        @selfimage = graph.get_picture(uself)
        @friendimage = graph.get_picture(ufriend)
        @eventtime = @ev['time'].strftime('%d. %B');

    end

    def close
    end
end
