class UsersController < ApplicationController

  def index
        oauth =   Koala::Facebook::OAuth.new(FACEBOOK_CONFIG["app_id"], FACEBOOK_CONFIG["secret"], "https://#{request.host}:#{request.port}/auth/facebook/callback")
        redirect_to oauth.url_for_oauth_code(:permissions => 
                  ['user_friends', 'user_photos', 'user_events',
                   'read_stream', 'publish_actions'])
  end

  def login
        auth = request.env["omniauth.auth"]
        session[:token] = auth['credentials']['token']
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
          output = {"status": "OK", "next": "FirstLoad", "friends": friend_data,
                    "text": "Finding your ideal UKE-friend!"}
          session[:fd] = friend_data
      when "FirstLoad"
          friend = FriendFinder.get_one_friend(session[:fd])
          output = {"status": "OK", "next": "Event", "text": "Your chosen friend is " + friend['name']}
      when "Friend"
          friend = FriendFinder.get_one_friend(session[:fd])
          output = {"status": "Done", "friend": friend}
      when "Event"
          event = Event.offset(rand(Event.count)).first
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
    #@friendprofile = graph.get_object(ufriend)
    @selfimage = graph.get_picture(uself)
    @friendimage = graph.get_picture(ufriend)

  end
end
