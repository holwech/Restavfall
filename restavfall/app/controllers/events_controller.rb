class EventsController < ApplicationController

  def index
    @user = Koala::Facebook::API.new(session[:token])
    @friends = session[:friendlist]
    @friend_data = @friends[session[:nextFriend]]

    unless defined?(offset) then
    	offset = rand(Event.count)
    end
    @event = Event.offset(offset).first

    @profile_image = @user.get_picture('me')
    @profile_image_friend = @user.get_picture(@friend_data['id'])
  end

  def newfriend
  	session[:nextFriend] += 1;
    if session[:nextFriend] == 51
    	session[:nextFriend] = 0
    end
    redirect_to '/events'
  end

  def newevent
  	offset = rand(Event.count)
  	redirect_to '/events'
  end
end
