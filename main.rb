#!/usr/bin/env ruby
#include Config constants for OS type
if defined?(Config)
  include Config
end

#gems
require 'rubygems'
require 'memcache'
require 'open-uri'
require 'rexml/document'
require 'pp'
require 'yaml'
require 'sequel'
require 'cgi'
require 'tzinfo'
require 'hpricot'
require 'net/http'
require 'uri'
require 'time'

if defined?(CONFIG) and CONFIG['host_os'] == "mswin32"
  require 'win32/process'
end

#load custom libraries
require 'core/logging.rb'
require 'core/lib/EM-Ruby-IRC/IRC.rb'
require 'core/includes.rb'
require 'core/remote_request.rb'
require 'core/memcache.rb'
require 'core/config.rb'

#setup database connection
require 'core/database.rb'

#setup config, takes yml config and sets it into the @@c global var.
setup_config

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
setup_models

#sets up memcache connection
setup_memcache

#message handler, load last
load 'core/handlers.rb' # TODO: Re-enable handlers

@@channels = nil
@@channels = {}

#load all of the core files from the modules
setup_modules

#connect to all networks.  If you only want to connect to a single network, send the network name as a argument (EG: IRC::Utils.connect('freenode'))
IRC::Utils.connect