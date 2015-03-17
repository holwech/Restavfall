class EventsController < ApplicationController

  def index
    @user = Koala::Facebook::API.new(session[:token])
    @profile_image = @user.get_picture('me')
  end
end
