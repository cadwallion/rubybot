module IRC
	class Setup
		def default_handlers
			@default_join_handler = Proc.new do |event|
				begin
					#Issues a who command on the channel when I join so I can generate the users hostnames
					event.connection.send_to_server "WHO #{event.message}" if event.from.downcase.chomp == event.connection.nickname.downcase.chomp
					#Make sure the bot has this channel in memory
					user = IRC::Utils.channel_user(event.connection, event.message, event.from, event.hostmask) #connection, channel, user
				rescue => err
					log_error(err)
				end
			end
			
			@default_names_reply_handler = Proc.new do |event|
				begin
					users = event.message.split
					users.each do |user|
						channel_user = IRC::Utils.channel_user(event.connection, event.mode, user) #connection, channel, user
					end
				rescue => err
					log_error(err)
				end
			end
			
			@default_part_handler = Proc.new do |event|
				begin
					if event.from.downcase.chomp == event.connection.nickname.downcase.chomp
						IRC::Utils.remove_channel(event.connection, event.channel)
					else						
						IRC::Utils.remove_channel_user(event.connection, event.channel, event.from)
					end
				rescue => err
					log_error(err)
				end
			end

			@default_who_reply_handler = Proc.new do |event|
				begin
					IRC::Utils.update_hostname(event.connection, event.stats[7], "#{event.stats[4]}@#{event.stats[5]}")
				rescue => err
					log_error(err)
				end
			end

			IRC::Utils.add_handler('join', @default_join_handler)
			IRC::Utils.add_handler('namreply', @default_names_reply_handler)
			IRC::Utils.add_handler('part', @default_part_handler)
			IRC::Utils.add_handler('whoreply', @default_who_reply_handler)
			IRC::Utils.add_handler('ping', lambda {|event| bot.send_to_server("PONG #{event.message}") })
		end
	end
end