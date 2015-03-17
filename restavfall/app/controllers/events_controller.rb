class EventsController < ApplicationController

  def index
    auth = request.env["omniauth.auth"]
    token = auth['credentials']['token']
    @user = Koala::Facebook::API.new(token)
    @profile_image = @user.get_picture('me')
  end
end
