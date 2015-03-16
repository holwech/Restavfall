class FriendFinder
    attr_accessor :friends, :graph

    def initialize(graph)
        self.friends = Hash.new{0}
        self.graph = graph
    end

    def get_friends
        puts "Getting friends"
        friend_values = self.friends.sort_by{|id, value|  value}.reverse.first(50)
        friend_data = self.graph.batch{|batch_api| 
            friend_values.each{|f| 
                batch_api.get_object("#{f[0]}?metadata=1", 
                         {fields:['name', 'metadata{type}']})}}
        friend_data.each_with_index{|d, i| 
            d['value'] = friend_values[i][1] }
        puts "Friends returned"
        return friend_data.select{|friend| friend['metadata']['type'] == 'user'}
    end

    def run_analysis
        puts "FriendFinder started"
        analyse_photos
        puts "FriendFinder done"
    end

    def analyse_photos
        ap_photos = get_album_photos
        tp_photos = get_tagged_photos
        photos = (ap_photos + tp_photos).uniq{|photo| photo['id']}
        photos.each do |photo|
            analyse_photo_tags(photo)
            analyse_photo_likes(photo)
            analyse_photo_comments(photo)
            add_photo_owner(photo)
        end
    end

    def get_album_photos
        albums = self.graph.get_connections('me', 'albums', {fields: 'id'})
        album_photos = self.graph.batch{|batch_api| 
            albums.each{|album| 
                batch_api.get_connections(album['id'], 'photos', 
                                      {fields: ['id', 'likes', 'comments', 'tags']})}}.flatten
        return album_photos
    end

    def get_tagged_photos
        tagged_photos = self.graph.get_connections('me', 'photos',
                                                      {fields: ['from', 'id', 'likes', 'comments', 'tags']})
        return tagged_photos
    end

    def analyse_photo_tags(photo)
        if photo.has_key?("tags")
            photo['tags']['data'].each do |tag|
                if tag.has_key?("id")
                    self.friends[tag['id']] += 1
                end
            end
        end
    end

    def analyse_photo_likes(photo)
        if photo.has_key?("likes")
            photo['likes']['data'].each do |like|
                self.friends[like['id']] += 1
            end
        end
    end

    def analyse_photo_comments(photo)
        if photo.has_key?("comments")
            photo['comments']['data'].each do |comment|
                self.friends[comment['from']['id']] += 1
            end
        end
    end

    def add_photo_owner(photo)
        if photo.has_key?("from")
            self.friends[photo['from']['id']] += 3
        end
    end
end
