class ChannelModule
	def self.join_channel(args, event)
		args = args.split
		unless Channel.find(:name => args[0])
			channel = Channel.create(:name => args[0])
			channel.save
			event.connection.join(args[0])
			return "Joined #{args[0]}"
		else
			event.connection.join(args[0])
			return "I am already in that channel"
		end
	end
	
	def self.part_channel(args, event)
		if event.channel =~ /^\#(.*)$/
			if channel = Channel.find(:name => event.channel)
				channel.destroy
				channel.save
				event.connection.part(event.channel)
				return "Left #{event.channel}"
			else
				event.connection.part(event.channel)
				return "I am not in that channel"
			end
		else
			return "You need to do that from inside a channel."
		end
	end

	def self.quiet(args, event)
		if event.channel =~ /^\#(.*)$/
			if channel = Channel.find(:name => event.channel)
				if channel.quiet == 1
					channel.quiet = 0
					channel.save
					return "Made #{event.channel} not quiet"
				else
					channel.quiet = 1
					channel.save
					return "Made #{event.channel} quiet"
				end
			else
				return "Could not find channel"
			end
		else
			return "You need to do that from inside a channel."
		end
	end

	def self.is_quiet?(channel)
		if channel =~ /^\#(.*)$/
			if channel = Channel.find(:name => channel)
				if channel.quiet == 1
					return true
				else
					return false
				end
			else
				return false
			end
		else
			return false
		end
	end

	def self.give_ops(args, event)
		if event.channel =~ /^\#(.*)$/
			event.connection.op(event.channel, event.from)
			return ""
		else
			return "You need to do that from inside a channel."
		end
	end
	def self.take_ops(args, event)
		if event.channel =~ /^\#(.*)$/
			event.conneevent.connectionctiondeop(event.channel, event.from)
			return ""
		else
			return "You need to do that from inside a channel."
		end
	end
	def self.kick(args, event)
		args = args.split(' ', 2)
		if event.channel =~ /^\#(.*)$/
			event.connection.kick(event.channel, args[0], args[1])
			return ""
		else
			return "You need to do that from inside a channel."
		end
	end
	def self.ban(args, event)
		args = args.split(' ', 2)
		if hostmask = UserModule.get_hostmask_for_nick(args[0], event)
			if event.channel =~ /^\#(.*)$/
				event.connection.mode(event.channel, "+b", hostmask)
				event.connection.kick(event.channel, args[0], args[1])
				return ""
			else
				return "You need to do that from inside a channel."
			end
		else
			return "Could not find user, try again in a few moments"
		end
	end
	def self.unban(args, event)
		args = args.split(' ', 2)
		if hostmask = UserModule.get_hostmask_for_nick(args[0], event)
			if event.channel =~ /^\#(.*)$/
				event.connection.mode(event.channel, "-b", hostmask)
				return ""
			else
				return "You need to do that from inside a channel."
			end
		else
			return "Could not find user, try again in a few moments"
		end
	end
	
	def self.join_channels_handler
		Proc.new do |event|
			begin
			Channel.all.each do |channel|
				if channel.password.nil?
					event.connection.join(channel.name)
				else              
					event.connection.join("#{channel.name} #{channel.password}")
				end
			end  
			rescue => err
				log_error(err)
			end
		end
	end
end


IRC::Utils.add_handler('endofmotd', ChannelModule.join_channels_handler)
IRC::Utils.add_handler('nomotd', ChannelModule.join_channels_handler)