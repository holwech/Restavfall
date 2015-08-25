class UkeEvent < ActiveRecord::Base
    has_many :uke_showings
    has_many :uke_fb_event
end
