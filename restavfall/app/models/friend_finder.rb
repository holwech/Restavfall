class FriendFinder
    attr_accessor :friends, :graph

    def initialize(graph)
        self.friends = Hash.new{0}
        self.graph = graph
    end

    def get_friends
        full_friends = []
        self.friends.each do |id, count|
            friend = self.graph.get_object(id)
            full_friends << {"data" => friend['name'], "value" => count}
        end
        full_friends.sort!{|a,b| a['value'] <=> b['value'] }
        return full_friends
    end

    def run_analysis
        analyse_photos
    end

    def analyse_photos
        ap_ids = get_album_photo_ids
        tp_ids = get_tagged_photo_ids
        ids = (ap_ids + tp_ids).uniq
        ids.each do |id|
            photo = self.graph.get_object(id)
            #puts "New photo"
            analyse_photo_tags(photo)
            analyse_photo_likes(photo)
            analyse_photo_comments(photo)
        end
    end

    def get_album_photo_ids
        photo_ids = []
        albums = self.graph.get_connections('me', 'albums')
        albums.each do |album|
            album_photos = self.graph.get_connections(album['id'], 'photos')
            album_photos.each do |photo|
                photo_ids << photo['id']
            end
        end
        return photo_ids
    end

    def get_tagged_photo_ids
        photo_ids = []
        tagged_photos = self.graph.get_connections('me', 'photos')
        tagged_photos.each do |photo|
            photo_ids << photo['id']
        end
        return photo_ids
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
