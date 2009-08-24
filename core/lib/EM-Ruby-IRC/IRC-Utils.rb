module IRC
	class Utils
		#Adds the channel to the global channel list (IRC::Connection#channels) and then returns it
		def self.channel(connection, channel_name)
			channel_name = channel_name.downcase.chomp
			channel = connection.channels.select { |obj| obj.name == channel_name }.first
			if channel.nil?
				channel = IRC::Channel.new(channel_name)
				connection.channels << channel
			end
			return channel
		end

		#Removes the user from the channel userlist, and if the user is not on any other channel userlists, it deletes it from global as well.
		def self.remove_channel_user(connection, channel_name, user_name)
			user_name = sanitize_nickname(user_name)
			channel_name = channel_name.downcase.chomp
			channel = channel(connection, channel_name)
			user = channel.users.select { |obj| obj.name == user_name }.first
			unless user.nil?
				channel.users.delete(user)
				keep_user = false
				connection.channels.each do |thischannel|
					unless thischannel.users.select { |obj| obj.name == user_name }.first.nil?
						keep_user = true
					end
				end
				connection.users.delete(user) unless keep_user
			end
		end

		#Removes the channel from the global channel list (IRC::Connection#channels)
		def self.remove_channel(connection, channel_name)
			channel_name = channel_name.downcase.chomp
			channel = connection.channels.select { |obj| obj.name == channel_name }.first
			connection.channels.delete(channel) unless channel.nil?
		end
		
		#Creates the user in the channel userlist (IRC::Channel#users) and then returns the user
		def self.channel_user(connection, channel_name, user_name, hostmask=nil)
		  return false if channel_name.nil? or user_name.nil?
			user_name = sanitize_nickname(user_name)
			channel_name = channel_name.downcase.chomp
			user = global_user(connection, user_name, hostmask)
			channel = channel(connection, channel_name)
			channel_user = channel.users.select { |obj| obj.name == user_name }.first
			if channel_user.nil?
				channel.users << user
			end
			return user
		end
		
		#Returns a user from an event.
		def self.get_channel_user_from_event(event, user=nil)
			if user.nil?
				channel_user(event.connection, event.channel, event.from)
			else
				channel_user(event.connection, event.channel, user)
			end
		end
		
		#Creates the user in the global userlist (IRC::Connection#users) and then returns the user
		def self.global_user(connection, user_name, hostmask=nil)
			user_name = sanitize_nickname(user_name)
			user = connection.users.select { |obj| obj.name == user_name }.first
			if user.nil?
				user = IRC::User.new(user_name, hostmask)
				connection.users << user
			end
			user.hostmask = hostmask unless hostmask.nil?
			return user
		end
		
		#Update the users hostmask
		def self.update_hostname(connection, user_name, hostmask)
			user_name = sanitize_nickname(user_name)
			user = connection.users.select { |obj| obj.name == user_name }.first
			user.hostmask = hostmask unless user.nil? or hostmask.nil?
			return user
		end
		
		def self.sanitize_nickname(nickname)
			return nickname.downcase.chomp.match(/(?![\@\%\&\+])([\-\_\[\]\{\}\\\|\`\^a-zA-Z0-9]*)/)[0]
		end
		
		#Converts a hostmask like *brian@*.google.com to .*brian@.*google.com so it can be properly used in a regex
		def self.regex_mask(hostmask)
			hostmask.gsub(/([\[\]\(\)\?\^\$])\\/, '\\1').gsub(/\./, '\.').gsub(/\[/, '\[').gsub(/\]/, '\]').gsub(/\*/, '.*').sub(/^/, '^').sub(/$/, '$')
		end
		
		#Sets up all connections into global @@connections
		def self.setup_connections(bot, config)
		  connections = {}
			config.each do |network, server_setup|
				connections[network] = IRC::Setup.new(bot, network, server_setup)
			end
			return connections
		end
		
	  def self.add_handler(eventname, proc, network)
		  network.add_startup_handler(lambda {|bot|
			  bot.add_message_handler(eventname, proc)
		  })
	  end
	end
end
