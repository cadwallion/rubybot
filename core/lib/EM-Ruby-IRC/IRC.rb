# This hash is used to store all of the connections, its the only global var set by the library
@@connections = Hash.new

require 'eventmachine'
require 'core/lib/EM-Ruby-IRC/IRC-Connection.rb'
require 'core/lib/EM-Ruby-IRC/IRC-Event.rb'
require 'core/lib/EM-Ruby-IRC/IRC-User.rb'
require 'core/lib/EM-Ruby-IRC/IRC-Channel.rb'
require 'core/lib/EM-Ruby-IRC/IRC-Utils.rb'
require 'core/lib/EM-Ruby-IRC/default-handlers.rb'

#TODO: need to make setup actually allow multiple connections and to handle all of the EM stuff

module IRC
	class Setup
		attr_reader :name, :config
		attr_accessor :connection, :startup_handlers, :memcache
		def initialize(name, config)
			@name = name
			@connection = nil
			@startup_handlers = Array.new
			@config = config
			@memcache = nil
			default_handlers
		end
		
		def add_startup_handler(proc=nil, &handler)
			startup_handlers << proc
		end

		def reset_startup_handlers
			startup_handlers.clear
		end
		
		def connect
			begin
				if defined?(EventMachine::fork_reactor)
					logger.debug("Event machine supports forking, attempting to fork.")
					EventMachine::fork_reactor {
						begin
							self.connection = EventMachine::connect(config["server_address"], config["server_port"].to_i, IRC::Connection, :setup => self)
						rescue => err
							log_error(err)
						end
					}
				else
					logger.warn("WARNING: Version of eventmachine does not support forking.  If you specified multiple connections you will only connect to one.")
					EventMachine::run {
						begin
							self.connection = EventMachine::connect(config["server_address"], config["server_port"].to_i, IRC::Connection, :setup => self)
						rescue => err
							log_error(err)
						end
					}
				end
			rescue => err
				log_error(err)
			end
		end
	end
end
