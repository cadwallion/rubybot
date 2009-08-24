class IRCHandler
	# determines if the command came from a PM or channel
	def self.get_target(event)
		if event.channel =~ /#(.*)/
			# event was a channel message
			#return event.from if ChannelModule.is_quiet?(event.channel) #TODO: re-enable this
			return event.channel
		else
			# event was a private message
			return event.from
		end
	end

	def self.is_pm?(event)
		if event.channel =~ /#(.*)/
			# event was a channel message
			#return event.from if ChannelModule.is_quiet?(event.channel) #TODO: re-enable this
			return false
		else
			# event was a private message
			return true
		end
	end
	
	# initial response block from the event handler
	def self.message_handler
		Proc.new do |event|
			begin
				# finds the event target
				target = get_target(event)
				# finds the event originator
				from_nick = event.from
				# gets the hostmask
				from_hostmask = event.hostmask
				# validates that event is a bot command.  check based on COMMAND_CHAR regex
				if event.message =~ Regexp.new("^#{event.connection.command_char}(.*)", true)
					# valid bot command, send to processor
					self.process_message(event)
				end
			rescue => err
				log_error(err)
			end
		end
	end

	# routes the event to the correct Object defined in commands.yml
	def self.process_message(event)
		begin
			unless event.message.nil?
				#Run it through a regex again to strip off the commmand char.
				if event.message =~ Regexp.new("^#{event.connection.command_char}(.*)", true)
					# slice up the information into two parts
					command_array = self.process_commands($1.strip, event.connection.setup.bot.commands)
					# crunch data down to one message Array
					return false if !command_array or command_array.nil? or command_array[0].nil? or command_array[1].nil?
					message = self.do_command(command_array[0], command_array[1].strip, event) 
					if message[0].class == Array
						message[0].each do |thismessage|
							if message[1] == "notice" or $1 =~ /^help/
								event.connection.send_notice(event.from, thismessage)
							else
								event.connection.send_message(self.get_target(event), thismessage)
							end
						end
					else
						if message[1] == "notice" or $1 =~ /^help/
							event.connection.send_notice(event.from, message[0])
						else
							event.connection.send_message(self.get_target(event), message[0])
						end
					end
				end
			end
		rescue => err
			log_error(err)
		end
	end

	def self.process_commands(command, commands)
		begin
			this_command = command.split(' ', 2)
			unless commands[this_command[0]].nil?
				command_options = commands[this_command[0]]
				unless this_command[1].nil?
					command_next = this_command[1]
					return process_commands(command_next, command_options) if process_commands(command_next, command_options)
				end
				command_args = this_command[1].nil? ? "" : this_command[1]
				return [command_options, command_args]
			else
				return false
			end
		rescue => err
			log_error(err)
		end
	end

	def self.do_command(command, args, event)
		begin
			return false if command.nil?
			unless command['out'].nil?
				return [command['out'], "message"]
			end
			unless command['command'].nil?
				num_args = command['num_args'].nil? ? 0 : command['num_args'].to_i
				opts = args.split(' ')
				if command['admin'] == 1
					return ["You need to be an admin.", "notice"] unless UserModule.is_admin?(event)
				end
                                if command['pm_only'] == 1
					return ["This command is usable via Private Message only.", "notice"] unless is_pm?(event)
				end
				if opts.size < num_args or (!command['regex'].nil? and !(args =~ Regexp.new(command['regex'], true)))
					unless command['help'].nil?
						return ["An error has occurred, check format. " + command['help'], "notice"]
					else
						return ["An unknown error has occurred", "notice"]
					end
				end
				output = eval(command['command'] + "(args, event)")
				if output != false
					return [output, "message"]
				else
					unless command['help'].nil?
						return ["An error has occurred, check format. " + command['help'], "notice"]
					else
						return ["An unknown error has occurred", "notice"]
					end
				end
			end
			unless command['help'].nil?
				return ["An error has occurred, check format. " + command['help'], "notice"]
			end
			return ["An unknown error has occurred", "notice"]
		end
	rescue => err
		log_error(err)
	end
end
