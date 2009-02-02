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

#custom libraries
require 'core/logging.rb'
require 'core/lib/EM-Ruby-IRC/IRC.rb'
require 'core/includes.rb'
require 'core/remote_request.rb'
require 'core/memcache.rb'

#setup database
require 'core/database.rb'

#config
require 'core/config.rb'

#setup config
setup_config

@@connections = Hash.new
@@c.each do |network, server_setup|
	@@connections[network] = IRC::Setup.new(network, server_setup)
end

#setup models from modules
setup_models

setup_memcache

#message handler, load last
load 'core/handlers.rb' # TODO: Re-enable handlers

@@channels = nil
@@channels = {}

setup_modules

@@connections.each do |name, connection|
	connection.connect
end