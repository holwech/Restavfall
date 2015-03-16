class FriendFinder
    attr_accessor :friends, :graph

    def initialize(graph)
        self.friends = Hash.new{0}
        self.graph = graph
    end

    def get_friends
        friend_values = self.friends.sort_by{|id, value|  value}.reverse.first(50)
        puts "Starting getting friends"
        friend_data = self.graph.batch{|batch_api| 
            friend_values.each{|f| 
                batch_api.get_object(f[0])}}
        friend_data.each_with_index{|d, i| 
            d['value'] = friend_values[i][1] }
        puts "Done getting friends"
        return friend_data
    end

    def run_analysis
        analyse_photos
    end

    def analyse_photos
        ap_photos = get_album_photos
        tp_photos = get_tagged_photos
        photos = (ap_photos + tp_photos).uniq{|photo| photo['id']}
        puts "Photos done"
        photos.each do |photo|
            #puts "New photo"
            analyse_photo_tags(photo)
            analyse_photo_likes(photo)
            analyse_photo_comments(photo)
        end
    end

    def get_album_photos
        photos = []
        albums = self.graph.get_connections('me', 'albums', {fields: 'id'})
        albums.each do |album|
            album_photos = self.graph.get_connections(album['id'], 'photos',
                                                      {fields: ['id', 'likes', 'comments', 'tags']})
            album_photos.each do |photo|
                photos << photo
            end
        end
        return photos
    end

    def get_tagged_photos
        photos = []
        tagged_photos = self.graph.get_connections('me', 'photos',
                                                      {fields: ['id', 'likes', 'comments', 'tags']})
        tagged_photos.each do |photo|
            photos << photo
        end
        return photos
    end

    def analyse_photo_tags(photo)
        if photo.has_key?("tags")
            photo['tags']['data'].each do |tag|
                if tag.has_key?("id")
                    self.friends[tag['id']] += 1
                    #puts "#{tag['name']} tagged"
                end
            end
        end
    end

    def analyse_photo_likes(photo)
        if photo.has_key?("likes")
            photo['likes']['data'].each do |like|
                self.friends[like['id']] += 1
                    #puts "#{like['name']} liked"
            end
        end
    end

    def analyse_photo_comments(photo)
        if photo.has_key?("comments")
            photo['comments']['data'].each do |comment|
                self.friends[comment['from']['id']] += 1
                #puts "#{comment['from']['name']} commented"
            end
        end
    end
end
