@@c = nil

class RubyBot
  def self.init
    require 'core/logging.rb'
    require 'core/lib/EM-Ruby-IRC/IRC.rb'
    require 'core/includes.rb'
    require 'core/remote_request.rb'
    require 'core/memcache.rb'
    require 'core/config.rb'
    require 'core/database.rb'

    #setup config, takes yml config and sets it into the @@c global var.
    RubyBot::Config.setup_config

    #@@c is a hash of the connection details.
    #{'network_name' => {
    #	'server_address' => 'irc.server.com',
    #	'server_port' => '6667',
    #	'nickname' => 'NickName',
    #	'realname' => 'Real Name',
    #	'nickserv_pass' => 'password',
    #	'bindip' => '66.98.192.58',
    #	'command_char' => '@',
    #	'memcache_host' => 'localhost',
    #	'memcache_port' => '11211',
    #	'memcache_namespace' => 'rubybot',
    #	'weather_par' => 'par',
    #	'weather_api' => 'api'
    #}

    IRC::Utils.setup_connections(@@c)

    #load all of the models from the modules
    RubyBot::Config.setup_models

    #sets up memcache connection
    RubyBot::Config.setup_memcache

    #message handler, load last
    load 'core/handlers.rb'
    load 'core/default_handlers.rb'

    @@channels = nil
    @@channels = {}

    #load all of the core files from the modules
    RubyBot::Config.setup_modules  
  end
  
  def self.connect
    unless ARGV[0].nil?
      IRC::Utils.connect(ARGV[0])
    else
      IRC::Utils.connect
    end
  end
end


