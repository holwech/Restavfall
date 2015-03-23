class EventsController < ApplicationController
	before_action :load

	SHUFFLE_LIMIT = 5

	def index
		@user = Koala::Facebook::API.new(session[:token])
		@friends = session[:friend_list]
		@friend = @friends[session[:next_friend]]

		@event = Event.offset(session[:next_event]).first
		@profile_image = @user.get_picture('me')
		@profile_image_friend = @user.get_picture(@friend['id'])
	end

	def show
		if params['id'] == 'newfriend'
			session[:next_friend] += 1
			if session[:next_friend] > 50
				session[:next_friend] = 0
			end
		elsif params['id'] == 'newevent'
			session[:next_event] += 1
			puts session[:next_event]
			if session[:next_event] >= Event.count
				session[:next_event] = 0
			end
		end
		puts 'clicked'
		redirect_to '/events'
	end

	def load
		if session[:new_visit] == 1
			friends = session[:friend_list]
			friends[0..(SHUFFLE_LIMIT - 1)] = friends[0..(SHUFFLE_LIMIT - 1)].shuffle
			session[:friend_list] = friends
			session[:next_friend] = 0

			events = Event.all
			events.shuffle
			session[:event_list] = events
			session[:next_event] = 0

			session[:new_visit] = 0			
		end
	end
end
