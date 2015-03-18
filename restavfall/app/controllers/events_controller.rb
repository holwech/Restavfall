class EventsController < ApplicationController

  def index
    @user = Koala::Facebook::API.new(session[:token])
    @profile_image = @user.get_picture('me')
    @event = Event.first
    @friends = session[:friendlist]
  end
end
