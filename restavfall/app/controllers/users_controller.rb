class UsersController < ApplicationController
  def index
  	@oauth = Koala::Facebook::OAuth.new(FACEBOOK_CONFIG["app_id"], FACEBOOK_CONFIG["secret"], "https://#{request.host}:#{request.port}/auth/facebook/callback")
  	session['oauth'] = @oauth

  	redirect_to @oauth.url_for_oauth_code
  end

  def login
  	#session['access_token'] = session['oauth'].get_access_token(params[:code])
    #@user = User.koala(session['access_token'])
    @data = session['oauth'].class.name
  end



end
