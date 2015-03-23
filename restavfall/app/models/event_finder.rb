class EventFinder
    attr_accessor :graph

    CUTOFF_DATE = '1-January-2011'

    def initialize(graph)
        self.graph = graph
    end

    def run_analysis
        likes = self.graph.get_connections('me', 'likes')

        names = ""
        keywords = ""

        begin
            likes.each do |l| 
                puts l['name']
                names += l['name']
                desc = self.graph.get_object(l['id'])
                keywords += desc['description']
            end
            likes = likes.next_page        
        end while not likes.nil?
    end
end
