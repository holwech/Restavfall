class UsersController < ApplicationController

  def index
  	@oauth =   Koala::Facebook::OAuth.new(FACEBOOK_CONFIG["app_id"], FACEBOOK_CONFIG["secret"], "https://#{request.host}:#{request.port}/auth/facebook/callback")
  	session['oauth'] = @oauth

  	redirect_to @oauth.url_for_oauth_code(:permissions => 
              ['user_friends', 'user_photos', 'user_events',
               'read_stream', 'publish_actions'])
  end

  def login
  	auth = request.env["omniauth.auth"]
    session[:token] = auth['credentials']['token']

    @user = Koala::Facebook::API.new(session[:token])
    @profile_image = @user.get_picture('me')
    @name = @user.get_object('me')['name']
    @permissions = @user.get_connections('me', 'permissions')

    ff = FriendFinder.new(@user)
    ff.run_analysis
    @friends = ff.get_friend_data
    @friend = ff.get_one_friend

    session[:friend_list] = @friends
    session[:new_visit] = 1
  end


end
