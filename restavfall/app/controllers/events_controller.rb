class EventsController < ApplicationController

  def index
    @oauth =   Koala::Facebook::OAuth.new(FACEBOOK_CONFIG["app_id"], FACEBOOK_CONFIG["secret"], "https://#{request.host}:#{request.port}/events/show")
    session['oauth'] = @oauth

    redirect_to @oauth.url_for_oauth_code(:permissions => 
              ['user_friends', 'user_photos', 'user_events',
               'read_stream', 'publish_actions'])
  end



  def show
    auth = request.env["omniauth.auth"]
    token = auth['credentials']['token']
    @user = Koala::Facebook::API.new(token)
    @profile_image = @user.get_picture('me')
  end
end
