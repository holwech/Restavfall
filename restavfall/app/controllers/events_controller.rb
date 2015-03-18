class EventsController < ApplicationController

  def index
    @user = Koala::Facebook::API.new(session[:token])
    @event = Event.first
    @friends = session[:friendlist]
    @friend_data = @friends[session[:nextFriend]]

    @profile_image = @user.get_picture('me')
    @profile_image_friend = @user.get_picture(@friend_data['id'])

    session[:nextFriend] += 1;
    if session[:nextFriend] == 51
    	session[:nextFriend] = 0
    end

  end
end
