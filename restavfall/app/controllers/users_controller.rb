class UsersController < ApplicationController

  def index
  	@oauth =   Koala::Facebook::OAuth.new(FACEBOOK_CONFIG["app_id"], FACEBOOK_CONFIG["secret"], "https://#{request.host}:#{request.port}/auth/facebook/callback")
  	session['oauth'] = @oauth

  	redirect_to @oauth.url_for_oauth_code
  end

  def login
  	auth = request.env["omniauth.auth"]
    token = auth['credentials']['token']
    @user = Koala::Facebook::API.new(token)
    @profile_image = @user.get_picture('me')
    @name = @user.get_object('me')['name']

    
    @test = @user.get_connections('me','friends').first['name']
  end


end
