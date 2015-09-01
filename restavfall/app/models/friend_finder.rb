class FriendFinder
    include ApplicationHelper

    TIME_LIMIT = 3

    COMMENT = 1
    LIKE = 1
    PHOTO_TAG = 2
    PHOTO_POSTER = 3
    WALL_POSTER = 5
    WALL_TAG = 4

    EVENT_UNDER_40 = 1
    EVENT_UNDER_20 = 2
    EVENT_UNDER_10 = 3
    EVENT_UNDER_5 = 4

    CUTOFF_DATE = '1-January-2010'

    def self.get_one_friend(graph, friend_data)
        # get list of friends not already chosen
        remaining_friends = friend_data.select{|f| not f.has_key?('chosen')}

        # If all friends have been chosen, reset list
        if remaining_friends.length == 0
            friend_data.each{|f| f.except!('chosen') }
            remaining_friends = friend_data
        end

        # Get sum of friend values
        sum = remaining_friends.map{|e| e['value']}.reduce(:+)
		if not sum
			return nil
		end
        trigger = Kernel::rand * sum
        counter = 0
        friend_data.each do |friend|
            if friend.has_key?('chosen')
                next
            end
            counter += friend['value']
            if counter > trigger
                friend['chosen'] = true;
                friend['pic'] = graph.get_picture(friend['id']);
                return friend
            end
        end
    end

    def self.make_friend_data(graph,  friend_scores, my_id)
        # Use only 50 first friends, and sort by descending value
        friends = friend_scores.
                                except(my_id).
                                sort_by{|id, value|  value}.
                                reverse.
                                first(50)

        # new batch request
        friend_data = graph.batch{|batch_api| 
            # for each friend
            friends.each{|f| 
                # get friend data
                batch_api.get_object("#{f[0]}?metadata=1", 
                                     {fields:['name', 'metadata{type}']})
            }
        }

        # Add friend value to friend data
        friend_data.each_with_index{|friend, i| 
            friend['value'] = friends[i][1] 
        }

        # exclude friends that are pages etc.
        friend_data = friend_data.select{|friend| 
            friend['metadata']['type'] == 'user'
        }
    end

    def self.analyse_photos(graph, friend_scores)
        ap_photos = FriendFinder.get_album_photos(graph)
        tp_photos = FriendFinder.get_tagged_photos(graph)
        photos = (ap_photos + tp_photos).uniq{|photo| photo['id']}
        photos.each do |photo|
            if photo.has_key?("tags")
                photo['tags']['data'].each do |tag|
                    if tag.has_key?("id")
                        friend_scores[tag['id']] += PHOTO_TAG
                    end
                end
            end
            if photo.has_key?("likes")
                photo['likes']['data'].each do |like|
                    friend_scores[like['id']] += LIKE
                end
            end
            if photo.has_key?("comments")
                photo['comments']['data'].each do |comment|
                    friend_scores[comment['from']['id']] += COMMENT
                end
            end
            if photo.has_key?("from")
                friend_scores[photo['from']['id']] += PHOTO_POSTER
            end
        end
    end

    def self.get_album_photos(graph)
        all_photos = []

        albums = graph.get_connections('me', 'albums', {fields: 'id'})

        ApplicationHelper.timeout(TIME_LIMIT) {
            album_photos = graph.batch{|batch_api| 
                albums.each{|album| 
                    batch_api.get_connections(album['id'], 
                          "photos?since=#{CUTOFF_DATE}", 
                          {fields: ['id', 'likes', 'comments', 'tags']})
                }
            }.flatten
            all_photos += album_photos
            albums = albums.next_page
        }.call{not albums.nil?}

        return all_photos
    end

    def self.get_tagged_photos(graph)
        all_photos = []

        photos = graph.get_connections('me', "photos?since=#{CUTOFF_DATE}",
                    {fields: ['from', 'id', 'likes', 'comments', 'tags']})

        ApplicationHelper.timeout(TIME_LIMIT) {
            all_photos += photos
            photos = photos.next_page
        }.call{not photos.nil?}

        return all_photos
    end


    def self.analyse_posts(graph, friend_scores)
        accepted_types = ['wall_post', 'shared_story', 'mobile_status_update']
        feed = graph.get_connections('me', 
                  "feed?filter=app_2915120374&since=#{CUTOFF_DATE}", 
                  {fields: ['from', 'comments', 'likes', 'with_tags', 
                            'message_tags', 'status_type']})

        ApplicationHelper.timeout(TIME_LIMIT) {
            feed.select{|f| accepted_types.include? f['status_type']}.each do |f|
                friend_scores[f['from']['id']] += WALL_POSTER;

                unless f['likes'].nil?
                    f['likes']['data'].each do |like|
                        friend_scores[like['id']] += LIKE
                    end
                end

                unless f['comments'].nil?
                    f['comments']['data'].each do |comment|
                        friend_scores[comment['from']['id']] += COMMENT
                    end
                end

                unless f['with_tags'].nil?
                    f['with_tags'].each do |_, v|
                        v.each{|tag| friend_scores[tag['id']] += WALL_TAG}
                    end
                end
                unless f['message_tags'].nil?
                    f['message_tags'].each do |_, v|
                        v.each{|tag| friend_scores[tag['id']] += WALL_TAG}
                    end
                end

            end
            feed = ApplicationHelper.time("Next feed page") {feed.next_page}
        }.call{not feed.nil?}
    end

    def self.analyse_events(graph, friend_scores)
        events = FriendFinder.get_events(graph)
        attendees = FriendFinder.get_event_attendees(events, graph)

        attendees.each do |event|
            if event['count'] > 40
                next
            elsif event['count'] > 20
                value = EVENT_UNDER_40
            elsif event['count'] > 10
                value = EVENT_UNDER_20
            elsif event['count'] > 5
                value = EVENT_UNDER_10
            else
                value = EVENT_UNDER_5
            end

            event['attending'].each do |friend|
                friend_scores[friend['id']] += value
            end
        end
    end

    def self.get_event_attendees(events, graph)
        attendees = []
        events.select{|e| e['attending_count'] < 40}.each_slice(25){|events_slice| 
            attendees << graph.batch{|batch_api| 
                events_slice.each {|event| 
                    callback = lambda {|arg| 
                        {"count" => event['attending_count'], "attending" => arg} 
                    }
                    batch_api.get_connections(event['id'], 'attending', &callback)
                }
            }
        }

        return attendees.flatten
    end

    def self.get_events(graph)
        event_ids = []
        events = graph.get_connections(
            'me', "events/attending?since=#{CUTOFF_DATE}",
            {fields: ['id', 'attending_count']})

        ApplicationHelper.timeout(TIME_LIMIT) {
            event_ids += events
            events = events.next_page
        }.call{not events.nil?}

        return event_ids.select{|e| e['attending_count'] <= 40}
    end
end
