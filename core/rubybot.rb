@@c = nil

#require gems and dependencies
require 'core/dependencies.rb'

require 'core/logging.rb'
require 'core/lib/EM-Ruby-IRC/IRC.rb'
require 'core/includes.rb'
require 'core/remote_request.rb'
require 'core/memcache.rb'
require 'core/config.rb'
require 'core/database.rb'

class RubyBot
  attr_accessor :connections, :config, :commands
  def initialize
    @commands = {}
    @config = {}
    @connections = {}
    setup
  end
	
  def setup
    #setup config, takes yml config and sets it into the @commands and @connections class vars.
    setup_config
    
    #load all of the models from the modules
    setup_models

    #sets up memcache connection
    setup_memcache

    #message handler, load last
    load 'core/handlers.rb'
    load 'core/defaults.rb'
    setup_defaults

    #load all of the core files from the modules
    setup_modules
  end

	#Connects to all (or a specific) servers
	def connect
    if ARGV[0].nil?
			self.connections.each do |name, connection|
				connection.connect
			end
		else
			self.connections[ARGV[0]].connect
		end
	end
	
	def add_handler(eventname, proc, network=nil)
		if network.nil?
			self.connections.each do |name, connection|
				connection.add_startup_handler(lambda {|bot|
					bot.add_message_handler(eventname, proc)
				})
			end
		else
			network.add_startup_handler(lambda {|bot|
				bot.add_message_handler(eventname, proc)
			})
		end
	end
end


