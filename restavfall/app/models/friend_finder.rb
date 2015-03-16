class FriendFinder
    attr_accessor :friends, :graph, :friend_data

    COMMENT = 1
    LIKE = 1
    PHOTO_TAG = 2
    PHOTO_POSTER = 3
    WALL_POSTER = 5
    WALL_TAG = 4

    def initialize(graph)
        self.friends = Hash.new{0}
        self.graph = graph
        self.friend_data = []
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
        puts "Getting friends"
        my_id = @graph.get_object('me', {fields: 'id'})['id']
        friend_values = self.friends.except(my_id).sort_by{|id, value|  value}.reverse.first(50)
        self.friend_data = self.graph.batch{|batch_api| 
            friend_values.each{|f| 
                batch_api.get_object("#{f[0]}?metadata=1", 
                                     {fields:['name', 'metadata{type}']})}}
        self.friend_data.each_with_index{|d, i| 
            d['value'] = friend_values[i][1] }
        puts "Friends gotten"
        self.friend_data = self.friend_data.select{|friend| friend['metadata']['type'] == 'user'}
    end

    def run_analysis
        puts "FriendFinder started"
        analyse_posts
        analyse_photos
        make_friend_data
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
        all_photos = []
        albums = self.graph.get_connections('me', 'albums', {fields: 'id'})

        begin
            album_photos = self.graph.batch{|batch_api| 
                albums.each{|album| 
                    batch_api.get_connections(album['id'], 'photos', 
                          {fields: ['id', 'likes', 'comments', 'tags']})}}.flatten
            all_photos += album_photos
            albums = albums.next_page
        end while not albums.nil?

        return all_photos
    end

    def get_tagged_photos
        all_photos = []

        photos = self.graph.get_connections('me', 'photos',
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
        feed = self.graph.get_connections('me', 'feed?filter=app_2915120374', {fields: ['from', 'comments', 'likes', 'with_tags', 'message_tags', 'status_type']})

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
            feed = feed.next_page
        end while not feed.nil?
    end
end
