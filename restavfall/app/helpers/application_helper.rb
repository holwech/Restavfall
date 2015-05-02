module ApplicationHelper
    @indent = 0
    def self.time(name, &block) #For debug only
        t = Time.now
        @indent += 1
        result = block.call
        @indent -= 1
        indentstr = "  "*@indent
        puts "#{indentstr}#{name} completed in #{(Time.now - t)} seconds"
        result
    end

    def self.timeout(time, &block)
        return lambda {|&cond|
            t = Time.now
            while true
                block.call
                diff = Time.now - t
                c = cond.call
                if (!c)
                    puts "Loop ended naturally after #{diff} seconds"
                    return
                elsif (diff > time)
                    puts "Loop stopped after #{diff} seconds"
                    return
                end
            end
        }
    end
end
