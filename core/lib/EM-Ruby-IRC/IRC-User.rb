module IRC
	class User
		attr_reader :name
		attr_accessor :hostmask, :user_data
		attr_writer :logged_in
		
		def initialize(name, hostmask=nil)
			@name = name
			@hostmask = String.new
			@hostmask = hostmask unless hostmask.nil?
			@logged_in = false
			@user_data = nil
		end
		
		def logged_in?
			@logged_in
		end
	end
end