class FriendFinder
    attr_accessor :friends, :graph, :friend_data, :indent

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

    CUTOFF_DATE = '1-January-2011'
    MAX_POST_PAGES = 4

    def time(name, &block) #For debug only
        t = Time.now
        self.indent += 1
        result = block.call
        self.indent -= 1
        indentstr = "  "*self.indent
        puts "#{indentstr}#{name} completed in #{(Time.now - t)} seconds"
        result
    end

    def initialize(graph)
        self.friends = Hash.new{0}
        self.graph = graph
        self.friend_data = []
        self.indent = 0
    end

    def get_one_friend
        sum = self.friend_data.map{|e| e['value']}.reduce(:+)
        trigger = Kernel::rand * sum
        counter = 0
        self.friend_data.each do |friend|
            counter += friend['value']
            if counter > trigger
                return friend
            end
        end
    end

    def get_friend_data
        self.friend_data
    end

    def make_friend_data
        my_id = @graph.get_object('me', {fields: 'id'})['id']
        friend_values = self.friends.except(my_id).sort_by{|id, value|  value}.reverse.first(50)
        self.friend_data = self.graph.batch{|batch_api| 
            friend_values.each{|f| 
                batch_api.get_object("#{f[0]}?metadata=1", 
                                     {fields:['name', 'metadata{type}']})}}
        self.friend_data.each_with_index{|d, i| 
            d['value'] = friend_values[i][1] }
        self.friend_data = self.friend_data.select{|friend| friend['metadata']['type'] == 'user'}
    end

    def run_analysis
        time("Run_analysis") {
            time("analyse posts"){analyse_posts}
            time("analyse_photos"){analyse_photos}
            time("analyse_events"){analyse_events}
            time("make_friend_data"){make_friend_data}
        }
    end

    def analyse_photos
        ap_photos = time("get album photos") {get_album_photos}
        tp_photos = time("get tagged photos") {get_tagged_photos}
        time("add photo points") {
            photos = (ap_photos + tp_photos).uniq{|photo| photo['id']}
            photos.each do |photo|
                analyse_photo_tags(photo)
                analyse_photo_likes(photo)
                analyse_photo_comments(photo)
                add_photo_owner(photo)
            end
        }
    end

    def get_album_photos
        all_photos = []
        albums = self.graph.get_connections('me', 'albums', {fields: 'id'})

        begin
            album_photos = self.graph.batch{|batch_api| 
                albums.each{|album| 
                    batch_api.get_connections(album['id'], 
                          "photos?since=#{CUTOFF_DATE}", 
                          {fields: ['id', 'likes', 'comments', 'tags']})
                }
            }.flatten
            all_photos += album_photos
            albums = albums.next_page
        end while not albums.nil?

        return all_photos
    end

    def get_tagged_photos
        all_photos = []

        photos = self.graph.get_connections('me', "photos?since=#{CUTOFF_DATE}",
                    {fields: ['from', 'id', 'likes', 'comments', 'tags']})

        begin
            all_photos += photos
            photos = photos.next_page
        end while not photos.nil?

        return all_photos
    end

    def analyse_photo_tags(photo)
        if photo.has_key?("tags")
            photo['tags']['data'].each do |tag|
                if tag.has_key?("id")
                    self.friends[tag['id']] += PHOTO_TAG
                end
            end
        end
    end

    def analyse_photo_likes(photo)
        if photo.has_key?("likes")
            photo['likes']['data'].each do |like|
                self.friends[like['id']] += LIKE
            end
        end
    end

    def analyse_photo_comments(photo)
        if photo.has_key?("comments")
            photo['comments']['data'].each do |comment|
                self.friends[comment['from']['id']] += COMMENT
            end
        end
    end

    def add_photo_owner(photo)
        if photo.has_key?("from")
            self.friends[photo['from']['id']] += PHOTO_POSTER
        end
    end

    def analyse_posts
        accepted_types = ['wall_post', 'shared_story', 'mobile_status_update']
        feed = time("get posts") {
            self.graph.get_connections('me', 
                  "feed?filter=app_2915120374&since=#{CUTOFF_DATE}", 
                  {fields: ['from', 'comments', 'likes', 'with_tags', 
                            'message_tags', 'status_type']})
        }

        time("add post points") {
            i = 0
            begin
                feed.select{|f| accepted_types.include? f['status_type']}.each do |f|
                    self.friends[f['from']['id']] += WALL_POSTER;

                    unless f['likes'].nil?
                        f['likes']['data'].each do |like|
                            self.friends[like['id']] += LIKE
                        end
                    end

                    unless f['comments'].nil?
                        f['comments']['data'].each do |comment|
                            self.friends[comment['from']['id']] += COMMENT
                        end
                    end

                    unless f['with_tags'].nil?
                        f['with_tags'].each do |_, v|
                            v.each{|tag| self.friends[tag['id']] += WALL_TAG}
                        end
                    end
                    unless f['message_tags'].nil?
                        f['message_tags'].each do |_, v|
                            v.each{|tag| self.friends[tag['id']] += WALL_TAG}
                        end
                    end

                end
                i += 1;
                if i == MAX_POST_PAGES
                    break
                end
                feed = time("new page") {feed.next_page}
            end while not feed.nil?
        }
    end

    def analyse_events
        events = time("get events") {get_events}
        attendees = time("get event attendees") {get_event_attendees(events)}

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
                self.friends[friend['id']] += value
            end
        end
    end

    def get_event_attendees(events)
        attendees = []
        events.each_slice(25){|events_slice| 
            attendees << self.graph.batch{|batch_api| 
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

    def get_events
        event_ids = []
        events = self.graph.get_connections(
            'me', "events/attending?since=#{CUTOFF_DATE}",
            {fields: ['id', 'attending_count']})

        begin
            event_ids += events
            events = events.next_page
        end while not events.nil?

        return event_ids.select{|e| e['attending_count'] <= 40}
    end
end
