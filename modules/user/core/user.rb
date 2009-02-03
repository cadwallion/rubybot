require 'digest/sha1'

class UserModule
	
	##########################
	## IRC COMMAND HANDLERS ##
	##########################

	def self.add_user(args, event)
		args = args.split
		nickname = args[0].downcase
		password = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{nickname}--")[0,6]
		unless User.find_by_nickname(nickname)
			hostmask = make_hostmask(IRC::Utils.get_channel_user_from_event(event, nickname).hostmask)
			user = User.create(:nickname => nickname)
			user.add_host(Host.create(:hostmask => hostmask))
			user.password = password
			user.save
			event.connection.send_notice(nickname, "User account for '#{nickname}' has been created with password '#{password}'")
			return "#{nickname} created with hostmask #{hostmask}"
		end
		return "That user already exists"
	end

	def self.delete_user(args, event)
		args = args.split
		nickname = args[0].downcase
		if user = User.find_by_nickname(nickname)
			user.destroy
			return "#{nickname} deleted"
		end
		return "That user doesn't exists"
	end
	
	def self.get_hostmask(args, event)
		hostmask = get_hostmask_for_nick(args.split[0].downcase, event)
		return "Hostmask for this user is #{hostmask}" unless hostmask == false or hostmask.nil? or hostmask == ""
		return "Error generating hostmast for user #{nick}"
	end

	def self.set_password(args, event)
		if event.channel.downcase == event.connection.nickname.downcase
			channel_user = IRC::Utils.get_channel_user_from_event(event)
			if channel_user.logged_in?
				user = channel_user.user_data
				return "Something went wrong" if user.nil?
				user.password = args
				user.save
				return "Updated password"
			end
			return "You must be logged in to change your password"
		else
			return "You must private message the bot to change your password.  /msg #{event.connection.nickname} #{event.connection.command_char}user password"
		end
	end

	def self.register(args, event)
		create_user(event)
		return "User created"
	end
	
	def self.login(args, event)
		if event.channel.downcase == event.connection.nickname.downcase
			args = args.split
			channel_user = IRC::Utils.get_channel_user_from_event(event)
			user = User.find(:nickname => args[0].downcase, :password => args[1])
			unless user.nil?
				channel_user.logged_in = true
				channel_user.user_data = user
				return "User logged in"
			else
				return "Could not log you in"
			end
		else
			return "You must private message the bot to login.  /msg #{event.connection.nickname} #{event.connection.command_char}login"
		end
	end

	def self.logout(args, event)
		channel_user = IRC::Utils.get_channel_user_from_event(event)
		if channel_user.logged_in?
			channel_user.logged_in = false
			channel_user.user_data = nil
			return "Logged out"
		else
			return "You are not logged in"
		end
	end
	
	def self.add_host(args, event)
		channel_user = IRC::Utils.get_channel_user_from_event(event)
		if channel_user.logged_in?
			user = channel_user.user_data
			user.add_host(Host.create(:hostmask => make_hostmask(channel_user.hostmask)))
			return "Added hostmask"
		end
		return "You must be logged in to change your password"
	end

	######################
	## UTILITY COMMANDS ##
	######################

	def self.create_user(event)
		begin
		user = get_user(event)
		if user.nil? or user == false
			hostmask = make_hostmask(IRC::Utils.get_channel_user_from_event(event).hostmask)
			password = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{event.from.downcase}--")[0,6]
			user = User.create(:nickname => event.from.downcase)
			user.add_host(Host.create(:hostmask => hostmask))
			user.password = password
			user.save
			event.connection.send_notice(event.from.downcase, "User account for '#{event.from.downcase}' has been created with password '#{password}'")
		end
		return user
		rescue => err
		log_error(err)
		end
	end
	
	def self.get_user(event)
		users = get_users(event)
		return users.first unless users.nil? or users.size == 0
		return false
	end

	def self.get_users(event)
		channel_user = IRC::Utils.get_channel_user_from_event(event)
		if channel_user.user_data.nil?
			users = Array.new
			hosts = Host.all.select { |obj| compare_hostmask(channel_user.hostmask, obj.hostmask) }
			hosts.each do |host|
				users << host.user
			end
		else
			users = Array.new
			users << channel_user.user_data
		end
		return users unless users.nil?
	end

	def self.is_admin?(event)
		user = IRC::Utils.get_channel_user_from_event(event)
		return true if user.logged_in? and user.user_data.admin == 1
		return false
	end

	def self.compare_hostmask(usermask, wildcardmask)
		return !!usermask.match(IRC::Utils.regex_mask(wildcardmask))
	end
	
	def self.make_hostmask(hostname)
		user = hostname.split('@', 2)[0]
		host = hostname.split('@', 2)[1]
		if host =~ /^(?:\d{1,3}\.){3}\d{1,3}$/
			hostsplit = host.split('.')
			host = "#{hostsplit[0]}.#{hostsplit[1]}.#{hostsplit[2]}.*"
		elsif host =~ /^.*(\..*\..*)$/
			host = "*#{$1}"
		end
		if user =~ /^(n|i)\=(.*)$/
			user = "#{$2}"
		elsif user =~ /^\~(.*)$/
			user = "#{$1}"
		end
		return "\*#{user}@#{host}"
	end
	
	def self.get_hostmask_for_nick(nick, event)
		nick = nick.downcase
		hostmask = IRC::Utils.get_channel_user_from_event(event, nick).hostmask
		return make_hostmask(hostmask) unless hostmask == false or hostmask.nil? or hostmask == ""
		return false
	end
end
