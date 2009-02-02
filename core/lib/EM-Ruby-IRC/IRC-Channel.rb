module IRC	
	class Channel
		attr_reader :name
		attr_accessor :users
		
		#Initialize channel and set userlist
		def initialize(name)
			@name = name
			@users = Array.new
		end
	end
end