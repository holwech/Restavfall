class UsersController < ApplicationController

  def index
  	@oauth =   Koala::Facebook::OAuth.new(FACEBOOK_CONFIG["app_id"], FACEBOOK_CONFIG["secret"], "https://#{request.host}:#{request.port}/auth/facebook/callback")
  	session['oauth'] = @oauth

  	redirect_to @oauth.url_for_oauth_code
  end

  def login
  	#session['access_token'] = session['oauth'].get_access_token(params[:code])
    #@user = User.koala(session['access_token'])
    @data = session['oauth'].class.name
  end

  def testNext
    @facebook_cookies ||= Koala::Facebook::OAuth.new('649498578495089', '845a0ce1a5a8be107cfc5b29bf94f634').get_user_info_from_cookie(cookies)
    #@access_token = @facebook_cookies["access_token"]
    #@graph = Koala::Facebook::API.new(@access_token)
    #@me = @graph.get_object("me")
  end


end
