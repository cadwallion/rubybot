require 'logger'

module IRC	
	class Connection < EventMachine::Connection
		attr_reader :realname, :username, :channels, :users, :name, :command_char
		attr_accessor :irc_handlers, :channels, :users, :setup, :nickname
	
		def initialize(args)
			begin
				@name = args[:setup].name
				@setup = args[:setup]
				@nickname = @setup.config["nickname"]
				@realname = @setup.config["realname"]
				@username = @setup.config["username"]
				@command_char = @setup.config["command_char"]
				@channels = Array.new
				@users = Array.new
				@irc_handlers = Hash.new()
				super
			rescue => err
				log_error(err)
			end
		end
		
		#Start handlers
    def post_init
      logger.debug("Firing post_init")
			begin
      	unless setup.startup_handlers.nil?
					setup.startup_handlers.each do |handler|
						handler.call(self) unless handler.nil?
					end
				end
			rescue => err
				log_error(err)
			end
		end

	def connection_completed
		logger.debug("Firing connection_completed")
		send_to_server "NICK #{@nickname}"
		send_to_server "USER #{@username} 8 * :#{@realname}"
	end

  	def receive_data(data)
			data.split("\n").each do |line|
				log_irc(line)
				IRC::Event.new(line, self)
			end
		end
		
		def send_to_server(message)
			log_irc(message)
			send_data "#{message}\n"
		end
		
		def unbind
			logger.info("[#{self.name}] Connection lost, sleeping 10 seconds")
			sleep 10
			logger.info("[#{self.name}] Reconnecting to: #{setup.config["server_address"]} Port: #{setup.config["server_port"]}")
			EventMachine::reconnect setup.config["server_address"], setup.config["server_port"].to_i, self
		end

		def add_message_handler(event_type, proc=nil, &handler)
			self.irc_handlers[event_type] = Array.new unless self.irc_handlers[event_type].class == Array
			self.irc_handlers[event_type] << proc
		end
		
		def log
			if @log.nil?
				@log = Logger.new("logs/#{@name}.log")
				@log.level = Logger::INFO
			end
			@log
		end

		def log_irc(line)
			log.info(line)
		end
		
		#Command helpers for easier coding (join, part, quit, kick, ban, etc)		
		def join(channel)
			send_to_server("JOIN #{channel}")
		end
		
		def part(channel)
			send_to_server("PART #{channel}")
		end
		
		def send_message(target, message)
			send_to_server("PRIVMSG #{target} :#{message}")
		end
		
		def send_notice(target, message)
			send_to_server("NOTICE #{target} :#{message}")
		end
		
		def quit(message)
			send_to_server("QUIT :#{message}")
		end
		
		def action(target, message)
			send_ctcp(target, 'ACTION', action);
		end
				  
		def ctcp(target, type, message)
			send_to_server("PRIVMSG #{target} :\001#{type} #{message}");
		end
		
		def kick(channel, target, message="Bye!")
			send_to_server("KICK #{channel} #{target} :#{message}")
		end
		
		def op(channel, target)
			mode(channel, "+o", target)
		end
		
		def deop(channel, target)
			mode(channel, "+o", target)
		end

		def mode(target, mode, arg=nil)
			send_to_server("MODE #{target} #{mode} #{arg}") unless arg.nil?
			send_to_server("MODE #{target} #{mode}")
		end
	end
end
